# OAuth2, SSO, and Identity Protocols — A Comprehensive Explanation

---

## Part A: Understanding OAuth2 and Related Concepts

### What Is OAuth2?

OAuth2 is an **authorization framework**, not an authentication protocol. This distinction is fundamental and frequently misunderstood.

- **Identification** answers "Who are you?" — that's authentication (e.g., logging in with a username/password).
- **Authorization** answers "What are you allowed to do?" — that's OAuth2's domain.
- It is indeed a **protocol** — specifically, an open standard defined by RFC 6749.

OAuth2 was designed to let an application (the *client*) act on behalf of a resource owner without the client ever seeing the owner's credentials. The authorization server issues an **access token** (typically a JWT) that grants the client limited access to specific resources, without exposing the user's actual password.

### OAuth2 Is Not Identification — It's Authorization With Delegated Trust

OAuth2 does **not** identify users in the same way an Identity Provider (IdP) like Keycloak or Google does via OpenID Connect (OIDC). OAuth2 alone does not produce identity information about the user. That comes from OIDC, which extends OAuth2 with an `id_token` (a signed JWT containing claims like `sub`, `name`, `email`).

So:
- **OAuth2** = authorization (access tokens for API access)
- **OIDC** = authentication + identity information (id_token with user claims)
- They are often used together, but they serve different purposes.

### Cross-Authority Authentication: Your Internal App and Kibana

You asked whether logging into Kibana means you accept the user as properly authenticated by a **different certificate authority** than your own. The answer is **yes**, and that's exactly how federated identity works.

When your internal Spring Boot app delegates authentication to Kibana (or vice versa) via OAuth2/OIDC:

1. Your app redirects the user to Kibana's authorization endpoint.
2. The user authenticates against Kibana's Identity Provider (which may use a different CA, key pair, and trust chain than your internal IdP).
3. Kibana returns an access token (and optionally an id_token via OIDC) to your app.
4. Your app trusts that token because it was issued by an **authorized OAuth2 client** — the trust relationship is established through OAuth2's Client Credentials flow or authorization code flow, not through a shared certificate authority.

The key insight: **OAuth2 does not require a shared CA**. Trust is established through the OAuth2 protocol itself — your app trusts Kibana's authorization server because you've registered it as an authorized client, and it verifies the token signature using the public key (via the JWKS endpoint) published by that server.

### How Single Sign-On (SSO) Typically Works

SSO is achieved through **OIDC** (OpenID Connect), which builds on OAuth2:

1. A user visits your application and attempts to access a protected resource.
2. The application redirects the user's browser to the Identity Provider's authorization endpoint, passing parameters including a `redirect_uri` and a `nonce` (to prevent replay attacks).
3. The IdP authenticates the user (e.g., password, MFA) and asks for consent.
4. The IdP issues an authorization code and redirects back to your application's callback URL.
5. Your application exchanges the authorization code for an access token and an **id_token** at the IdP's token endpoint.
6. The id_token is a JWT containing identity claims (e.g., `sub`, `name`, `email`).
7. Subsequent requests to other SSO-enabled applications use the same session — the user only authenticates once, and all applications trust each other via their shared OIDC provider.

The **session** aspect of SSO is typically managed by a **cookie** set by the IdP at its own domain (e.g., `.keycloak.example.com`). Other applications participate in SSO because they redirect to this same IdP, not because they share cookies.

### Websites That Let You "Log In With Google" — Are They Using OAuth2 and SSO?

**Yes.** The "Sign in with Google" button uses OIDC (which is built on top of OAuth2):

- **OAuth2 layer**: Google acts as the authorization server, issuing access tokens that let your application call Google APIs on the user's behalf.
- **OIDC layer**: Google issues an `id_token` containing identity claims about the user, which your application uses to create a user session (or link to an existing account).
- **SSO aspect**: If you're logged into Google in your browser, clicking "Sign in with Google" on another site does not require re-authentication — that's SSO. The Google session cookie enables this.

If you are not logged into Google, you'll be prompted to authenticate — that's the authentication step happening at Google's IdP.

### What Is the Typical Purpose of Keycloak?

Keycloak is an **open-source Identity and Access Management (IAM)** solution that provides:

1. **Identity Provider** (authentication): User login, social login (Google, GitHub, etc.), MFA — this is the OIDC part.
2. **Authorization Server**: OAuth2/OIDC token issuance, client registration, scopes, roles.
3. **Single Sign-On**: Browser-based SSO across all applications that trust Keycloak as their IdP.
4. **User Federation**: Connecting to existing directories (LDAP, AD) rather than maintaining user data in Keycloak itself.
5. **Session Management**: Managing browser sessions and token lifetimes.

In your architecture, Keycloak could serve as the central OIDC provider that all your applications trust — including Spring Boot, Kibana, Grafana, and Google integrations.

---

## Part B: Your Three-Site Architecture — Protocols, Tokens, Cookies, and CSRF

### The Four Services in Your Setup

1. **Spring Boot microservice** — acting as an authentication authority and business application
2. **Elastic + Kibana** — search/visualization platform with its own auth system
3. **Grafana stack** — monitoring/dashboards with its own auth system
4. **Google service (e.g., Google Drive)** — external OAuth2/OIDC provider

### Which Protocols Are Relevant?

| Service | Authentication Protocol | Authorization Protocol | Token Format |
|---|---|---|---|
| Spring Boot app | OIDC (OpenID Connect) / JWT Bearer | OAuth2 | JWT (access_token, id_token) |
| Kibana | OpenSearch-based auth / OIDC (via plugin) | OAuth2 (optional) | JWT or session-based tokens |
| Grafana | OIDC (OAuth2/OIDC plugin) | OAuth2 (optional) | Session cookies + access tokens |
| Google (Drive API) | OIDC (Google as IdP) | OAuth2 | JWT (access_token, id_token) |

**Yes, both OAuth2 and JWT are relevant.** The typical pattern is:
- **OAuth2** defines the protocol for obtaining access tokens.
- **JWT** is the format of those access tokens (and the OIDC `id_token`). A JWT is a signed JSON object — it can be verified without contacting the issuer, which is critical for performance.

### Cookies vs. Tokenless (Bearer) Architecture

This is a crucial distinction in security design:

#### Browser-Based Authentication with Cookies (SSO-Prone to CSRF)

When you log into an application through a browser:

1. **The IdP sets a session cookie** at its domain (e.g., `keycloak.example.com`).
2. **The application may set its own session cookie** after validating the OAuth2 callback and creating a local session.
3. **This cookie is sent automatically by the browser on every request**, which means:
   - It enables SSO — your browser carries credentials across sites via redirects to the IdP.
   - **It makes you vulnerable to CSRF (Cross-Site Request Forgery)** — any malicious site can trigger a request with cookies attached.

**Which services in your setup use this model?**

- **Kibana**: Kibana uses browser sessions with cookies by default. When you log in via the browser, it sets a cookie that persists across requests and navigation within Kibana's domain. This is vulnerable to CSRF — which is why Kibana implements CSRF protection headers (e.g., `X-Requested-With` validation).
- **Grafana**: Grafana also uses browser cookies for session management when using its default login flow. Similarly CSRF-sensitive.
- **Spring Boot app**: If your Spring Boot app uses OAuth2/OIDC with the Authorization Code flow and stores sessions server-side with a cookie, it's also vulnerable to CSRF on authenticated endpoints (but not on token-based API calls).

#### Token-Based / Bearer Authentication (Cookieless — Immune to CSRF)

When the application exchanges the authorization code for an access token **and then uses that token directly**:

1. The browser sends a request with `Authorization: Bearer <JWT>` header.
2. **No cookie is required** — the browser does not send the token automatically; it must be included explicitly by the client code.
3. **This is immune to CSRF** because an attacker cannot make another site's JavaScript include a specific `Authorization` header on cross-site requests (due to CORS and HTTP header restrictions).

**Which services use this model?**

- **Spring Boot API endpoints**: REST APIs typically use JWT Bearer tokens, not cookies. This is the standard — cookieless, CSRF-immune.
- **Grafana API calls**: When Grafana communicates with its API via programmatic access (e.g., provisioning), it uses API keys or bearer tokens, not browser cookies.
- **Google Drive API calls from your Spring Boot backend**: If your app acts as the client and calls Google Drive on behalf of a user, it stores the access token server-side and presents it via `Authorization: Bearer` headers.

### Summary Table: Cookie vs. Token Architecture

| Service | Default Auth Mechanism | Cookie? | CSRF Risk? |
|---|---|---|---|
| Spring Boot (browser login) | OIDC + session cookie | Yes | Yes — on browser endpoints |
| Spring Boot (API calls) | JWT Bearer token | No | No |
| Kibana (browser UI) | Session-based auth | Yes | Yes |
| Kibana (API calls) | API key / bearer token | No | No |
| Grafana (browser UI) | Session cookie + OAuth2/OIDC | Yes | Yes — on browser endpoints |
| Grafana (API/provisioning) | API key / bearer token | No | No |
| Google Drive (backend client) | Bearer token via OAuth2 | No | No |

### Key Takeaways

1. **OAuth2 = authorization** (access tokens for API access). **OIDC = authentication + identity** (id_token with user claims). They are complementary, often used together.

2. **SSO works by having all applications trust a single Identity Provider**. The SSO session lives in the IdP's cookie domain (e.g., `*.keycloak.example.com`), not in the individual application domains. Each application participates by redirecting to the IdP and trusting its tokens.

3. **Cross-CA authentication is normal in federated identity**. OAuth2/OIDC does not require a shared certificate authority — trust is established through client registration and JWT signature verification via JWKS endpoints.

4. **Cookies enable SSO but create CSRF vulnerability**. Bearer tokens (JWT in the `Authorization: Bearer` header) are cookieless, immune to CSRF, and should be preferred for API access. The critical distinction is between browser-based sessions (cookie-dependent, CSRF-sensitive) and machine-to-machine or programmatic access (token-header-based, CSRF-immune).

5. **Keycloak's purpose** is to centralize all of this — acting as the IdP (OIDC), authorization server (OAuth2), SSO session manager, and federation broker for your entire architecture.
