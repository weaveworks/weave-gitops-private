# 3. Authentication and Authorization

Date: 2021-08-04

## Status

Proposed

## Context

This is a proposal for authenticating an authorizing requests made to backend API components that are part of Weave GitOps.

## Authentication vs Authorization

First off, let's clarify the terms, _Authentication_ is the process of
establishing _who_ someone is, we do this all the time on the Internet, by
providing credentials in exchange for a Cookie.

Ideally we'd do this in a secure manner, so that we could trust who the
authenticated user is, and also, we'd be able to delegate the authentication to
someone else, so that we don't have to maintain username/password lists.

The "authenticated user" can be described generically as a [_Principal_](https://en.wikipedia.org/wiki/Principal_(computer_security)).

_Authorization_ is the term for determining whether or not a user or Principal can
perform an operation.

For example, in online banking, you might authenticate as "user@example.com", but that does not
mean you can transfer money from "welloff@example.com", the code should check
with the authorization components to check whether or not this is allowed.

Kubernetes (and GitHub) provide Role-Based Access Control ([RBAC](https://en.wikipedia.org/wiki/Role-based_access_control)) to mediate access to objects.

The [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) mechanisms allow you to control operations on objects declaratively.

For example, this role declaratively allows read-only access to _Secret_ objects.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
rules:
- apiGroups:
    - ""
  resources:
    - secrets
  verbs:
    - get
```

To grant access to secrets, we create a binding between a role and a subject (Principal).

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-secrets
  namespace: default
subjects:
- kind: User
  name: user@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

This grants the user `user@example.com` permissions to read secrets, through the
`secret-reader` Role defined above.

Subjects can be of _Kind_ `User` or `Group`, allowing fairly fine-grained
access-control declarations.

It's possible to be more specific in the Role definition, and apply the role to
specific objects.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
rules:
- apiGroups:
    - ""
  resources:
    - secrets
  verbs:
    - get
  resourceNames:
    - test-secret
```

This is more specific, and grants the `get` permission on the secret
`test-secret`.

## Guiding Principle

 > Users should not get different access to objects through our APIs than they
 > would have if using kubectl

What this means, is that if you run `kubectl get <object kind>` at the command
line, the list of objects returned should be the same as we would use to render
a display in the UI.

This allows tooling like kubectl to be used to diagnose issues.

  `$ kubectl auth can-i get deploy/my-test-deploy`

## Decision

## OIDC

This is a proposal to use OIDC to delegate the authentication, and rely on Kubernetes RBAC for the authorization, with a fallback to something like Open Policy Agent ([OPA](https://www.openpolicyagent.org/)) or [Kyverno](https://kyverno.io/) where there is no practical RBAC option.

### OIDC?

[OIDC](https://openid.net/connect/) delegates authentication to services, and
standardises the authentication token as a JWT with an extensible
[Claims](https://openid.net/specs/openid-connect-core-1_0.html#Claims) based
approach to providing data to make it easier to perform the authorization part
of the problem.

Kubernetes has [native support](https://kubernetes.io/docs/reference/access-authn-authz/authentication/) for authenticating via OIDC 

### Kubernetes Impersonation

The final part of the puzzle is [Kubernetes client impersonation](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation), the clients we use to interact with the Kubernetes API in our components can impersonate 

To impersonate a Principal in a client request, we need to configure the [ImpersonationConfig](https://pkg.go.dev/k8s.io/client-go/rest#ImpersonationConfig) on the [rest.Config](https://pkg.go.dev/k8s.io/client-go/rest#Config) that is used to communicate with the Kubernetes API.

```go
	cfg.Impersonate =  rest.ImpersonationConfig{
			UserName: "user to impersonate",
			Groups:   []string{"groups", "to", "impersonate"},
		}
	}
```

`UserName` and `Groups` should match the configuration of the `RoleBinding`
described above.

The `ServiceAccount` that the container process is executing as needs to be
given the "impersonate" permission on objects that need access.

This allows the security of components to be strictly controlled.

## Technical implementation

### Browser Authentication

We would request an OIDC ID Token as part of the authentication flow.

This is described in the Dex [documentation](https://dexidp.io/docs/using-dex/#requesting-an-id-token-from-dex).

In our code, we'd need a simple variation of the [sample](https://github.com/dexidp/dex/tree/master/examples/example-app) code provided by Dex,
 specifically, it would need to make additional claims for the group membership.

```go
// These are GitHub claims
var claims struct {
	Email             string   `json:"email"`
	Groups            []string `json:"groups"`
}
```
The resulting ID Token would then be put into a browser cookie, probably along
with the refresh token.

This is a signed JWT token and thus protected against token tampering.

## Validating API requests in servers

This is also described in the Dex [documentation](https://dexidp.io/docs/using-dex/#consuming-id-tokens).

For backend services implemented in Go, we wrap the exposed [http.Handler](https://pkg.go.dev/net/http#Handler) in a middleware that validates incoming tokens in a known cookie or request header.

This uses an implementation of this interface, which is responsible for identifying an authenticated Principal from the request.

```go
// PrincipalGetter implementations are responsible for extracting a named
// principal from a request.
type PrincipalGetter interface {
	// Principal extracts a principal from the http.Request.
	// It's not an error for there to be no principal in the request.
	Principal(r *http.Request) (*UserPrincipal, error)
}
```
For an OIDC Authentication ID, this can be parsed using the standard Go [OIDC package](https://github.com/coreos/go-oidc).
```go
mux := http.NewServeMux()
mux.Handle("/path/to/thing", func(w http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(w, "just a response")
})
// This is from github.com/coreos/go-oidc/v3/oidc
// And is boilerplate verification logic
provider, err := oidc.NewProvider(ctx, issuerURL) // issuerURL is the Dex server URL
verifier := provider.Verifier(&oidc.Config{ClientID: clientID}) // This services ClientID

// This wraps the mux in a new Middleware that verifies JWT cookies (named
auth-cookie) and puts the Principal into the request Context.
http.ListenAndServe(":8080", middleware.PrincipalMiddleware(middleware.NewJWTCookieVerifier(verified, "auth-cookie"), mux))
```
I've implemented "multi-auth" for these, to allow for either cookie, or header-based authentication.

## Super-user

We want to duplicate the "Admin" user from ArgoCD, this is fairly trivial to
implement as a specialised principal extraction function something like this:

```go
// BasicAuthPrincipal returns the user from a Basic auth Authorization header.
func BasicAuthPrincipal(r *http.Request) (*UserPrincipal, error) {
    username, password _ := r.BasicAuth()
    if username == "" {
        return nil, nil
    }
    // securely compare the password with the contents of a "secret" and return
    // an error if they don't
    return &UserPrincipal{ID: username}, nil
}
```

The interface above is responsible for interpreting a request, and establishing
the principal to use from that.


## Using the principal in requests...

Generally, we want a [`*rest.Config`](https://pkg.go.dev/k8s.io/client-go/rest#Config) which can then
be used to create the appropriate client to talk to the Kubernetes API.

This is behind an API that accepts a context, and returns a configured
`rest.Config`.

```go
// ConfigGetter implementations should extract the details from a context and
// create a *rest.Config for use in clients.
type ConfigGetter interface {
    Config(ctx context.Context) *rest.Config
}
```

One implementation of this that works with the previously described middleware
looks like this:

```go
// FromContext implements the ConfigGetter interface.
func (r *ImpersonatingConfigGetter) Config(ctx context.Context) *rest.Config {
    shallowCopy := *r.cfg
    if p := middleware.Principal(ctx); p != nil {
        shallowCopy.Impersonate = rest.ImpersonationConfig{
            UserName: p.ID,
            Groups:   p.Groups,
        }
    }
    return &shallowCopy
}
```

If there is a Principal in the context, then the returned `*rest.Config` will be
configured to impersonate.

If there is none, then it will fall back to the service-account of the executing
container.

## Consequences

By delegating the authentication part to an OIDC provider, we can integrate easily with existing solutions for authenticating users, the native K8s support for OIDC means we can apply the principle defined earlier:

 > Users should not get different access to objects through our APIs than they
 > would have if using kubectl

K8s native OIDC support means that access is tied to the same principal as the native RBAC, if customers choose to do this.

By tying the authentication token for accessing our APIs to an externally issued token we don't need to maintain our own tokens, and so we are removing a host of potential compromises, and we also don't need to build our own RBAC ontop of K8s.

One downside, is that requires an external authentication system, this is fine for larger organisations who already have SSO solutions in place, but is likely not suitable for smaller organisations who don't.

I don't believe we should get into the business of storing user accounts, or groups, this leads to building complex systems to manage groups and provide functionality that we don't likely want to maintain.

There's nothing inherent in the design that precludes this tho', implementations
of the `PrincipalGetter` interface are free to interpret `http.Request`s in any
way they like, to identify a Principal.
