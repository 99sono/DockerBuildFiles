# Sub-Agent 3: OAuth2, SSO, and Identity Protocols

## Part (a) — Concepts and Foundations

### Is OAuth2 identification? Authorization? A protocol?

OAuth 2.0 is none of these things in a simple way — it is **an authorization framework** defined by [RFC 6749](https://tools.ietf.org/html/rfc6749). Specifically:

| Aspect | Answer | Explanation |
|---|---|---|
| **Is it identification?** | **No.** OAuth2 does not authenticate the user's identity. It does not answer "who is this person?" It answers "what may this client do on behalf of the resource owner?" |
| **Is it authorization?** | **Yes.** OAuth2 is purely an authorization framework. It authorizes a client application to access resources on behalf of a resource owner (the end user), without sharing the user's credentials with the client. |
| **Is it a protocol?** | **Yes.** It is an open protocol / standard that defines how authorization works across multiple parties (resource owner, client, authorization server, resource server). |

OAuth2 is often confused with authentication. That confusion exists because:

1. It is frequently deployed **alongside** the [OpenID Connect (OIDC)](https://openid.net/specs/openid-connect-core-1.0.html) protocol, which *does* provide authentication (identification) by issuing an ID Token (a JWT).
2. Many "login with Google/GitHub" flows look like authentication to end users, but what OAuth2 actually grants the client is **access** to a Google API, not a verification of the user's identity.

OAuth2 defines four grant types:

1. **Authorization Code Grant** — for server-side (confidential) clients. The user is redirected to the authorization server, consents, and receives an authorization code that the backend exchanges for an access token.
2. **Implicit Grant** — deprecated (RFC 8849); was for browser-based clients, returning tokens directly in the URL fragment.
3. **Resource Owner Password Credentials Grant** — the client directly collects username/password from the user (rarely recommended, as it requires trusting the client with credentials).
4. **Client Credentials Grant** — for machine-to-machine authorization where there is no end user.

### Does OAuth2 operate between two different authorization servers?

This is a subtle but important question. Let's break it down.

OAuth2 does **not** operate *between* two authorization servers. Instead, OAuth2 describes a relationship among **four roles**:

1. **Resource Owner** — the user who owns the data.
2. **Client** — the application requesting access to the data (e.g., my internal app).
3. **Authorization Server** — the server that authenticates the resource owner and issues access tokens (e.g., Keycloak).
4. **Resource Server** — the server hosting the protected resources (e.g., Kibana, Google Drive).

The scenario you describe — *my internal app* and *Kibana* — can be mapped as follows:

- My internal app acts as the **client**.
- Keycloak (or another IdP) acts as the **authorization server**.
- Kibana acts as the **resource server**.

OAuth2 itself does **not** handle the trust relationship between two different authorization servers. That is the job of **federated identity** (e.g., OIDC with discovery, PKCE, and trust configuration). But here is how it works in practice:

1. My internal app directs the user to my **own** authorization server (e.g., Keycloak).
2. The user authenticates at Keycloak (using my CA, my identity infrastructure).
3. Keycloak issues an access token (and optionally an ID Token via OIDC).
4. My app presents that token to Kibana.
5. Kibana, if configured to trust that token, accepts it.

If Kibana is the one that initiates auth (e.g., the user goes to Kibana first and is redirected to Keycloak), then Kibana uses Keycloak's authorization server to authenticate. In either case, **OAuth2 tokens are not exchanged between two authorization servers** — instead, a single authorization server issues tokens that are accepted by multiple resource servers.

The phrase "*accept the user as properly authenticated by a different certificate authority than my own*" points toward **certificate-based trust** or **identity federation**. OAuth2 does not handle certificates for authentication directly — TLS handles transport security, and the CA validates the HTTPS connection. The identity itself is validated by the authorization server using whatever credentials mechanism it has defined (password, MFA, LDAP, SAML, OIDC federation).

**Key takeaway:** OAuth2 authorizes *access*, it does not authenticate *identity* between two authorization servers. If my app and Kibana both trust the same authorization server (e.g., Keycloak), then a user authenticated at one can be authorized at the other — but this is identity federation / single sign-on, not OAuth2-to-OAuth2 token exchange between authorization servers.

### How does Single Sign-On (SSO) typically work?

SSO means the user authenticates **once** and gains access to **multiple** applications without re-entering credentials. Here is the typical flow (using the Authorization Code + OIDC flow as the canonical example):

1. **User visits App A.** App A detects no valid session/token and redirects the user's browser to the **Authorization Server** (IdP) with an OAuth2 authorization request (including a client ID, redirect URI, scope, state, and nonce).
2. **User authenticates at IdP.** The IdP checks if the user already has a session. If yes, the user is already logged in (this is the "single" in SSO). If no, the IdP presents a login page.
3. **User consents.** The IdP may present a consent screen asking what the app is allowed to access.
4. **IdP redirects back.** The IdP sends the user back to App A's redirect URI with an **authorization code**.
5. **App A exchanges code for tokens.** App A's backend sends the code (and its client secret) to the IdP's token endpoint and receives an **access token** (for API access) and an **ID Token** (a JWT containing identity claims via OIDC).
6. **App A creates a session.** App A sets a session cookie or stores the session server-side.
7. **User visits App B.** App B detects no session and redirects to the same IdP with its own authorization request.
8. **IdP skips login.** Because the user still has an active session at the IdP, no login is needed. The IdP immediately redirects back with an authorization code for App B.
9. **Apps B exchanges code for tokens** — same as Step 5.
10. **Result:** The user logged in once and is now simultaneously authenticated at both App A and App B.

The **session at the IdP** is the key — it is typically maintained via a secure, HttpOnly, SameSite cookie on the IdP's domain. All apps that trust the IdP can redirect to it, and the IdP's session cookie enables the silent re-authorization that makes SSO possible.

### Are websites that let you log in with Google using OAuth2 and SSO?

**Both. Yes.**

"Login with Google" (Google OAuth 2.0 / OpenID Connect) is a canonical example of both OAuth2 and SSO:

- **OAuth2 aspect:** Your application requests authorization to access Google APIs on behalf of the user (e.g., read Gmail, access Google Drive). The authorization code is exchanged for an access token and an ID token.
- **SSO aspect:** Once the user has authenticated with Google and authorized your app, they can visit another app that also supports "Login with Google" and be authenticated there without re-entering credentials, because Google maintains the session cookie.

The user experience is:

1. User clicks "Login with Google" on Website A → redirected to Google login → consents → redirected back to Website A.
2. Later, user visits Website B → clicks "Login with Google" → Google sees the existing session → redirected back to Website B **without showing a login page**.

Google is the **Identity Provider (IdP)** / Authorization Server. Website A and Website B are **Clients**. If the user then uses their Google OAuth token to access Google Drive, Google Drive is the **Resource Server**.

### What is the typical purpose of Keycloak?

**Keycloak is an open-source Identity and Access Management (IAM) solution.** Its typical purposes include:

1. **Centralized Authentication** — It acts as the Authorization Server in the OAuth2/OIDC model. Applications (clients) redirect users to Keycloak for login instead of managing their own auth logic.
2. **Single Sign-On (SSO)** — Keycloak maintains a session for the user. Any client that trusts Keycloak can redirect to it, and the user gets authenticated without re-entering credentials.
3. **Protocol Support** — Keycloak supports OAuth2, OpenID Connect, SAML 2.0, and LDAP/Active Directory federation. This makes it a universal identity broker that can connect to various identity sources (LDAP, Active Directory, social logins like Google, etc.).
4. **User Federation** — Instead of maintaining users in Keycloak's database, you can connect it to your existing LDAP/AD, allowing employees to use their corporate credentials across all federated applications.
5. **Role-Based Access Control (RBAC)** — Keycloak can assign roles and groups to users and pass these in tokens so downstream applications can enforce access policies.
6. **Delegation & Fine-Grained Policies** — Using Keycloak's Policy Enforcer, you can define granular access rules for specific URIs or resources in protected applications.

In a typical enterprise architecture, Keycloak replaces the need to build custom OAuth2/OIDC infrastructure. All applications (Spring Boot, Kibana, Grafana, etc.) can be configured to trust Keycloak as their IdP.

---

## Part (b) — Multi-System Protocol Analysis

### Systems under consideration:

| # | System | Typical Role |
|---|---|---|
| 1 | Spring Boot microservice (auth authority + business apps) | Client(s) and potentially Authorization Server (if Keycloak is not used); also Resource Server |
| 2 | Elastic + Kibana | Resource Server (Elastic) + Client / Resource Server (Kibana, depending on config) |
| 3 | Grafana stack | Resource Server (Grafana) + Client |
| 4 | Google service (e.g., Google Drive) | Resource Server (and Google is also an Authorization Server / IdP for all "Login with Google" clients) |

### Protocols involved at each level

#### 1. Spring Boot Microservice

| Protocol | Role | Details |
|---|---|---|
| **OIDC / OAuth2** | Identity & Authorization | If Keycloak is deployed, the Spring Boot app uses the **Authorization Code + PKCE** flow (or standard Authorization Code flow with client secret) to authenticate users. The ID Token (JWT) carries identity claims; the Access Token (JWT or opaque) is used to access APIs. |
| **JWT** | Token format | ID Tokens and Access Tokens are typically JWTs. The Spring Boot app validates them using the JWKS (JSON Web Key Set) from the IdP (Keycloak). |
| **Cookie (session)** | Browser session | After OIDC login, Spring Boot typically creates an **HttpOnly, Secure, SameSite=Strict/Lax** session cookie. This cookie is **sensitive to CSRF** — mitigation via SameSite cookie attribute and/or CSRF tokens. |
| **SAML** (optional) | Enterprise federation | Spring Boot apps often use SAML SP to connect to enterprise IdPs via Keycloak's SAML bridge. |

#### 2. Elastic + Kibana

| Protocol | Role | Details |
|---|---|---|
| **OIDC / OAuth2** | User Authentication | Kibana can be configured with an OIDC provider (Keycloak, Google, etc.) in recent versions. Users are redirected to the IdP for login. Kibana receives an ID Token and Access Token. |
| **JWT** | Token validation | Kibana validates JWT ID Tokens from the IdP. For accessing Elasticsearch API, Kibana uses an Elasticsearch API key or basic auth internally. |
| **Cookie (session)** | Browser session | Kibana maintains a session cookie for authenticated users. **This is vulnerable to CSRF.** Mitigation requires SameSite cookies, CSRF tokens, or cookie-free token patterns. |
| **API Key / Bearer Token** | Machine-to-machine | Elasticsearch also supports bearer authentication where API keys or JWTs are sent in the `Authorization: Bearer <token>` header. This is **cookieless and immune to CSRF** (CSRF exploits form submissions, not programmatic HTTP requests). |

**Elasticsearch (backend):** The actual Elastic data layer is typically accessed via API calls using API keys or bearer tokens — **no cookies, no CSRF risk** at the Elastic layer.

**Kibana (frontend):** The Kibana UI runs in the browser, serves an HTML page, sets cookies, and is **subject to CSRF** if authentication relies on cookies. Using bearer tokens in `Authorization` headers for API calls within the Kibana UI mitigates this.

#### 3. Grafana Stack

| Protocol | Role | Details |
|---|---|---|
| **OIDC / OAuth2** | User Authentication | Grafana supports OIDC login (Keycloak, Google, Azure AD, etc.). The user is redirected to the IdP, authenticates, and is redirected back with auth code exchanged for tokens. |
| **JWT** | Token handling | Grafana receives JWT ID tokens from the IdP and maps OIDC claims (email, groups) to Grafana user attributes. |
| **Cookie (session)** | Browser session | Grafana sets a session cookie. **This is vulnerable to CSRF.** Grafana recommends using short-lived sessions, SameSite cookies, and CSRF tokens. |
| **Service Account Token / Bearer Token** | Machine access | Grafana's API supports bearer token authentication. Dashboards and data sources can use service account tokens via `Authorization: Bearer <token>`. **Cookieless, CSRF-immune.** |

**Grafana as a data source consumer:** When Grafana queries Elastic/Kibana, it typically uses service account tokens or basic auth — **cookieless programmatic communication.**

#### 4. Google Service (Google Drive)

| Protocol | Role | Details |
|---|---|---|
| **OIDC / OAuth2** | User Authorization | Google Drive uses OAuth2 extensively. Any app that "Connects to Google Drive" goes through the Google OAuth2 authorization flow. Google is the Authorization Server and Resource Server. |
| **JWT** | Token format | OAuth2 tokens from Google are JWTs. The access token can be used to make API calls to Google Drive. |
| **Cookie (browser session)** | Google's own auth | Google maintains its own session cookie for authenticated google.com accounts. **Vulnerable to CSRF.** Mitigated via SameSite=Lax (Google's implementation). |
| **Bearer Token** (primary) | API access | Google Drive API calls use `Authorization: Bearer <access_token>` headers. **Cookieless, CSRF-immune.** |

---

### JWT (JSON Web Token) — Where does it fit?

**JWT is a token format, not a protocol.** It is the standard format used by both OAuth2 (access tokens) and OpenID Connect (ID tokens, refresh tokens). In this architecture:

- **Spring Boot:** Validates JWTs from Keycloak, extracts claims (sub, email, roles), and uses them for authorization decisions.
- **Kibana:** Validates JWT from the IdP for user identity; may also generate or use JWT for backend Elastic API auth.
- **Grafana:** Validates JWT from IdP for user identity mapping.
- **Google Drive:** Issue JWT access tokens that clients use to authenticate API requests.

JWT is **not a cookie** — it is typically carried in HTTP headers:

```
Authorization: Bearer <jwt_token>
```

When tokens are passed this way, **CSRF attacks do not apply**, because CSRF exploits the browser's automatic inclusion of cookies in requests. Browser-managed headers like `Authorization` must be set programmatically (e.g., via JavaScript `fetch()`), which the browser's same-origin policy prevents cross-site code from doing.

---

### Cookie Sensitivity & CSRF Attack Surface

This is a critical security distinction. Let me lay it out clearly.

#### Systems that USE cookies and are SENSITIVE to CSRF:

| System | Cookie Used By | CSRF Risk | Mitigation |
|---|---|---|---|
| **Spring Boot UI** (if serving HTML) | Spring Session cookie | **HIGH** — form submissions from malicious sites can carry the session cookie | SameSite=Strict/Lax cookie attribute; CSRF tokens in forms; `X-XSRF-TOKEN` header |
| **Kibana UI** | Kibana session cookie | **HIGH** — the Kibana dashboard can be trivially CSRF-targeted | SameSite=Lax cookie; disable direct form-based actions; use cookie-free token-based auth where possible |
| **Grafana UI** | Grafana session cookie | **MODERATE-HIGH** — Grafana has had CSRF vulnerabilities in the past | Grafana's CSRF middleware; SameSite=Strict cookies; short session TTLs |
| **Google (google.com)** | Google session cookie | **MODERATE** — Google has strong CSRF protections | SameSite=Lax (Google's default); strict origin policies |

**Why are these vulnerable?** Because they authenticate via cookies stored by the browser. An attacker's page at `malicious.com` can trigger the victim's browser to send a request to the target system — the browser automatically includes the cookie, and the target system treats the request as authorized.

#### Systems/operations that are COOKIELESS and CSRF-IMMUNE:

| System | Token Passing Method | CSRF Risk | Why |
|---|---|---|---|
| **Spring Boot API** (stateless) | `Authorization: Bearer <jwt>` in HTTP header | **NONE** | CSRF only affects requests where the browser auto-includes credentials (cookies). Explicitly-set headers are not auto-included by cross-site requests. |
| **Kibana → Elasticsearch** | API Key or Bearer token via HTTP header | **NONE** | Programmatic communication, no cookies involved. |
| **Grafana API / Service Accounts** | `Authorization: Bearer <service_account_token>` | **NONE** | Token in header, not cookie. |
| **Google Drive API** | `Authorization: Bearer <access_token>` | **NONE** | Same reason — tokens in headers. |
| **All OIDC/OAuth2 token exchanges** (backend-to-IdP) | Token sent via HTTPS POST body from server-side code | **NONE** | The exchange is programmatic, server-to-server. No browser cookie involvement. |

---

### Summary: Protocol Map Across the Architecture

```
┌───────────────────────────────────────────────────────────────────────┐
│                        IDENTITY LAYER                                  │
│                                                                        │
│   [Keycloak / Google]  ── OIDC + OAuth2 ── JWT ── SSO ── Cookie ──┐  │
│   (Authorization Server / IdP)                                    │  │
│   ─── User authenticates once, gets session cookie,              ───┼──┐
│   ─── issues ID Token (JWT) + Access Token (JWT)                  │  │
│   ─── supports SAML, LDAP, social logins                          │  │
└───────────────────────────────────────────────────────────────────────┘
                                             │
                    ┌──────────────────────────┼──────────────────┐
                    ▼                          ▼                  ▼
         ┌─────────────────┐   ┌──────────────────┐  ┌──────────────────┐
         │ Spring Boot     │   │ Elastic + Kibana │  │ Grafana          │
         │ App (Client +   │   │ Kibana: Client + │  │ App (Client +    │
         │ Resource Server)│   │ Resource Server) │  │ Resource Server) │
         └─────────────────┘   └──────────────────┘  └──────────────────┘
                    │                          │                  │
         Cookie + CSRF-sensitive          Cookie + CSRF-       CSRF-
         (login UI)                       sensitive            sensitive (login UI)
         JWT in Authorization header     JWT for IdP          JWT for IdP,
         (stateless APIs)                validation           Bearer token for
         Sessions stored server-side     Cookie on Kibana     API calls, cookie-
         CSRF: SameSite + tokens         Cookie on UI        less for data queries
                    └──────────────────────┼──────────────────┘
                                           │
                    ┌──────────────────────┼──────────────────┐
                    ▼                      ▼                  ▼
         ┌─────────────────┐   ┌──────────────────┐          │
         │ Elastic         │   │ Grafana queries  │          │
         │ (via API key)   │   │ Service account  │          │
         │ Bearer token    │   │ Bearer tokens    │          │
         │ COOKIELESS      │   │ COOKIELESS       │          │
         │ CSRF-IMMUNE     │   │ CSRF-IMMUNE      │          │
         └─────────────────┘   └──────────────────┘          │
                                                           ▼
                                              ┌──────────────────┐
                                              │ Google Drive     │
                                              │ OAuth2 / OIDC    │
                                              │ JWTs             │
                                              │ Cookie on UI     │
                                              │ Bearer in API    │
                                              └──────────────────┘
```

### Key Takeaways

1. **OAuth2 = Authorization, Not Authentication.** If you need identification, layer OpenID Connect (OIDC) on top of OAuth2, which provides the ID Token (JWT with claims).
2. **JWT is a token format, not a protocol.** It is used by OAuth2/OIDC, SAML (indirectly), and independently. It is typically transmitted via the `Authorization: Bearer` HTTP header.
3. **SSO works via the IdP's session cookie.** The user logs into the Identity Provider once. All clients that trust the IdP can redirect to it and silently re-authorize, because the IdP still recognizes the user.
4. **"Login with Google" = OAuth2 + OIDC + SSO.** Google is the IdP and authorization server. Your apps are clients. The user gets authenticated across all apps without re-entering credentials.
5. **Keycloak = your enterprise IdP.** It centralizes authentication, supports multiple protocols (OAuth2, OIDC, SAML, LDAP), and serves as the single source of truth for identities and access policies across all your applications.
6. **Frontend UIs with cookies = CSRF-vulnerable.** Spring Boot UIs, Kibana, and Grafana login interfaces use cookies and must be protected with SameSite cookies, CSRF tokens, or equivalent.
7. **Backend API calls with bearer tokens = CSRF-immune.** Any communication where tokens are sent in the `Authorization` header (Spring Boot APIs, Kibana→Elastic, Grafana→Elastic, Drive API calls) is immune to CSRF attacks.
