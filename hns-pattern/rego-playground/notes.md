# NOTES

As we have seen in previous tickets, deploying an IAM Policy from a cluster can easily be done via:
```
#iam-policy-member-ex1.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: iampolicymember-test-sa-1
  namespace: a-spi-controller
spec:
  member: serviceAccount:test-sa-1@a-spi-controller.iam.gserviceaccount.com
  role: roles/storage.objectViewer
  resourceRef:
    kind: Project
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    external: projects/a-spi-controller
```

However, the goal of the current task is to remove the external reference as to block users from sending cross-project references. Removing the external field will cause a failure in the deployment, in order for the deployment to work without external an annotation will have to be added within the metadata (apiVersion can be removed with the annotation added).

```
#iam-policy-member-ex2.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: iampolicymember-test-sa-2
  namespace: a-spi-controller
  annotations:
    cnrm.cloud.google.com/project-id: a-spi-controller
spec:
  member: serviceAccount:test-sa-1@a-spi-controller.iam.gserviceaccount.com
  role: roles/logging.viewer
  resourceRef:
    kind: Project
```

Still, this won't stop someone from just adding *external* to the request, in order to do that we will have to implement a policy. As we have seen before policies have 2 parts, a template and a constraint. The template itself also has 2 parts, the first part defines the fields the constraint will use whereas the second part contains the rego code. In this case the template is the following:

```
#template.yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8stestext
spec:
  crd:
    spec:
      names:
        kind: K8sTestExt
      validation:
        openAPIV3Schema:
          properties:
            invalidName:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sdenyext
        has_key(x, k) {
            _ = x[k]
          }
        violation[{"msg": msg}] {
          has_key(input.review.object.spec.resourceRef, input.parameters.invalidName)
          msg := sprintf("The name %v is not allowed", [input.parameters.invalidName])
        }
```

The rego basically creates a function that checks if a 'dictionary' has a certain key, and then it runs the function against the input, which it compares to the invalidName provided in the constraint. To better explain this the constraint use is as follows:

```
#constraint.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sTestExt
metadata:
  name: no-external-a-spi-name
  namespace: a-spi-controller
spec:
  parameters:
    invalidName: "external"
```

In other words, the constraint will set invalidName from the template function to "external". The same constraint can obviouslly be used to set other fields from the request as invalid, hence why we use templates. Also, something I noticed is that we cannot deploy both a tempalte and a constraint that references it in the same request. They will need to be separate .yaml files, and will have to be deployed sequentially, otherwise the constraint deployment will fail.

With both the template and constraint in place, trying to deploy iam-policy-member-ex1.yaml again will cause a failure.