kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: spire-broker-abac
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: __REPO_ABSPATH__/abac-policy.jsonl
        containerPath: /etc/kubernetes/abac/policy.jsonl
        readOnly: true
    kubeadmConfigPatches:
      - |
        kind: ClusterConfiguration
        apiServer:
          extraArgs:
            authorization-mode: Node,ABAC
            authorization-policy-file: /etc/kubernetes/abac/policy.jsonl
          extraVolumes:
            - name: abac-policy
              hostPath: /etc/kubernetes/abac
              mountPath: /etc/kubernetes/abac
              readOnly: true
              pathType: DirectoryOrCreate
