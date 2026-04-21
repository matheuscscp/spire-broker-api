package main

import (
	"context"
	"fmt"
	"os"

	authorizationv1 "k8s.io/api/authorization/v1"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/client/config"
)

// Simulates what SPIRE server would do: ask the apiserver (via SubjectAccessReview)
// whether the broker's identity can perform the 'impersonate' verb on the requested
// Kubernetes object. SPIRE uses its OWN credentials — no impersonation, no broker-side
// RBAC requirement.
func main() {
	ctx := context.Background()

	brokerNS := os.Getenv("BROKER_NAMESPACE")
	brokerSA := os.Getenv("BROKER_SA")
	objGroup := os.Getenv("OBJ_GROUP")
	objResource := os.Getenv("OBJ_RESOURCE")
	objNS := os.Getenv("OBJ_NAMESPACE")
	objName := os.Getenv("OBJ_NAME")

	cfg, err := config.GetConfig()
	if err != nil {
		die("kubeconfig: %v", err)
	}
	c, err := client.New(cfg, client.Options{})
	if err != nil {
		die("client: %v", err)
	}

	brokerUser := fmt.Sprintf("system:serviceaccount:%s:%s", brokerNS, brokerSA)
	brokerGroups := []string{
		"system:serviceaccounts",
		fmt.Sprintf("system:serviceaccounts:%s", brokerNS),
		"system:authenticated",
	}

	review := &authorizationv1.SubjectAccessReview{
		Spec: authorizationv1.SubjectAccessReviewSpec{
			User:   brokerUser,
			Groups: brokerGroups,
			ResourceAttributes: &authorizationv1.ResourceAttributes{
				Verb:      "impersonate",
				Group:     objGroup,
				Resource:  objResource,
				Namespace: objNS,
				Name:      objName,
			},
		},
	}
	if err := c.Create(ctx, review); err != nil {
		die("SAR: %v", err)
	}
	fmt.Printf("broker=%s/%s  target=%s/%s  ns=%s  name=%s  => allowed=%v denied=%v reason=%q\n",
		brokerNS, brokerSA, objGroup, objResource, objNS, objName,
		review.Status.Allowed, review.Status.Denied, review.Status.Reason)
}

func die(f string, a ...any) {
	fmt.Fprintf(os.Stderr, f+"\n", a...)
	os.Exit(1)
}
