# spire-broker-api

PoC for [spiffe/spiffe#340 (comment)](https://github.com/spiffe/spiffe/pull/340#issuecomment-4214923594): SPIRE authorizes a broker requesting SVIDs for a Kubernetes object by asking the apiserver if the broker has `impersonate` on that object.

Tests the same scenarios across three kind clusters with different `--authorization-mode`.

## Recommendation: use `SubjectAccessReview`, not `SelfSubjectAccessReview`

|                        | SSAR (original proposal)                 | SAR (this PoC)                  |
|------------------------|------------------------------------------|---------------------------------|
| Subject supplied via   | impersonation                            | `spec.user` / `spec.groups`     |
| Needs perms on broker  | yes: `create selfsubjectaccessreviews`   | no                              |
| Needs perms on SPIRE   | `serviceaccounts:[impersonate]` + SSAR   | `create subjectaccessreviews`   |
| Works on non-RBAC      | broker-side grant must be added manually | nothing extra needed            |

SSAR "just works" on RBAC clusters because `system:basic-user` grants SSAR to every authenticated user by default. ABAC/Webhook clusters have no such default, so the SSAR design leaks a requirement onto every broker. SAR keeps the one permission on the one trusted component.

## Results

| # | Scenario                                    | RBAC   | ABAC   | AlwaysAllow |
|---|---------------------------------------------|--------|--------|-------------|
| 1 | `broker-allowed` → `widgets/demo/widget-1`  | allow  | allow  | allow       |
| 2 | `broker-allowed` → `widgets/demo/widget-2`  | deny † | allow ‡| allow       |
| 3 | `broker-denied`  → `widgets/demo/widget-1`  | deny   | deny   | allow       |
| 4 | `broker-allowed` → `widgets/other/widget-1` | deny   | deny   | allow       |

† RBAC `resourceNames: [widget-1]` scopes per-object. ‡ ABAC has no `resourceName` field.

Takeaways: SAR delegates to whatever authorizer is configured (RBAC, ABAC, Webhook). Granularity tracks the authorizer — per-object needs RBAC. `AlwaysAllow` disables auth entirely; SPIRE should probe with a known-should-deny SAR at startup and refuse to run if the answer is `allowed=true`.

## Run it

Requires `kind`, `kubectl`, `docker`, `go`.

```sh
make all      # create 3 clusters, run all scenarios
make clean    # tear down
```

Individual modes: `make rbac`, `make abac`, `make alwaysallow`.
