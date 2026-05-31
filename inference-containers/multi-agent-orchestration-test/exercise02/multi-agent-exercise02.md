# Experiment 02 — Task Prompts

Use four sub-agents with the model `dgx-spark/qwen3.6-35b`. Each sub-agent should explain a different topic.
Before you lunch the execution of the sub-agents you must ask in which diretory the sub-agents should write their output.
Let files be called:
- agent_01_linear_transformations.md
- agent_02_eigenvalues.md
- agent_03_oauth2.md
- agent_04_web_security_jargon.md

---

## Sub-Agent 1: Linear Transformations

(a) What are the fundamental principles of a linear transformation? Specifically:

- If `f(a + b)` must be equivalent to `f(a) + f(b)`
- And `f(2a)` must be equivalent to `2 * f(a)`
- And `f(0) = 0`

(b) Many so-called "linear" functions are actually **not** linear transformations. Is that right?

- `f1(x) = mx` — this **is** a linear transformation.
- `f2(x) = mx + b` — this is **not** a linear transformation when `b != 0`, because `f(0) = b`, which violates the principle `f(0) = 0`.

---

## Sub-Agent 2: Eigenvalues

Explain what so-called **eigenvalues** are. Adapt your explanation to each of the following audiences:

- As if you were a Harvard professor teaching a class.
- As if you were a high school teacher teaching a class.
- As if you were a primary school teacher teaching a class.
- As if you were an intelligent parent explaining to a 5-year-old child.

---

## Sub-Agent 3: OAuth2, SSO, and Identity Protocols

(a) What is OAuth2? Consider these questions:

- Is it identification? Is it authorization? Is it a protocol?
- Does it operate between two different authorization servers — for example, my internal app and Kibana — where logging into Kibana means I accept the user as properly authenticated by a different certificate authority than my own?
- How does Single Sign-On (SSO) typically work?
- Are the websites that let you log in with a Google account using OAuth2 and SSO?
- What is the typical purpose of Keycloak?

(b) Imagine you have the following three sites:

1. A Spring Boot microservice app acting as an authentication authority, along with other business apps.
2. Elastic + Kibana.
3. A Grafana stack.
4. A Google service (e.g., Google Drive).

Consider the following:

- What protocols are relevant here?
- Is it JWT (JSON Web Token)?
- Is it OAuth2 as well?
- Which of these elements create cookies in your browser and are sensitive to CSRF attacks, and which are cookieless — relying solely on browser requests carrying tokens?

---

## Sub-Agent 4: Web Browser Attacks and Security Policies

Please explain the following web browser attacks and security policies clearly.

(a) What is CORS, and how does it relate to site malfunctions when embedding iframes without a reverse proxy?

(b) Can an attacker circumvent CORS by simply serving a hacked website in a top-level window, paired with an iframe pointing to your banking site? Or does this not work because the attacker cannot exploit a reverse proxy — since the attacker does not have the bank's private certificate, and the bank's certificate would only be valid for the bank's own URLs, which the attacker cannot imitate?

(c) What is CSRF? Is this the type of attack where a compromised top-level window on an attacker's site forces requests you never intended to make to a banking site, with your `JSESSIONID` cookies being sent automatically?

(d) There are a few other well-known terms in web security jargon beyond CSRF and CORS. Can you expand the list with other popular names?
