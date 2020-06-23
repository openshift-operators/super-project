#!/usr/bin/env bash

NAMESPCAE="super-project-operator"
IMAGE=$1
TAG=$2

if [[ -z $IMAGE ]]; then
 printf "You must provide image repository with name!!!\n"
 exit 1
fi

if [[ -z $TAG ]]; then
 printf "You must provide image tag!!!\n"
 exit 1
fi




printf "Create operator project\n"
cat <<EOF | oc apply -f-
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPCAE}
spec: {}
EOF

printf "Create or update CRD\n"
cat <<EOF | oc apply -f-
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
    name: superprojects.automation.ocp.io
spec:
    group: automation.ocp.io
    names:
      kind: Superproject
      listKind: SuperprojectList
      plural: superprojects
      singular: superproject
    scope: Namespaced
    subresources:
      status: {}
    #    validation:
    #      openAPIV3Schema:
    #        type: object
    #        x-kubernetes-preserve-unknown-fields: true
    versions:
      - name: v1
        served: true
        storage: true
EOF


printf "Create service account roles and cluster rolebindings\n"
cat <<EOF | oc apply -f-
---
apiVersion: v1
kind: ServiceAccount
metadata:
   namespace: ${NAMESPCAE}
   name: super-project
---
apiVersion: authorization.openshift.io/v1
groupNames: null
kind: ClusterRoleBinding
metadata:
  name: super-project-cluster-admin
roleRef:
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: super-project
    namespace: ${NAMESPCAE}
userNames:
  - system:serviceaccount:${NAMESPCAE}:super-project
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: ${NAMESPCAE}
  name: super-project
subjects:
  - kind: ServiceAccount
    name: super-project
roleRef:
  kind: Role
  name: super-project
  apiGroup: rbac.authorization.k8s.io

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ${NAMESPCAE}
  name: super-project
rules:
  - apiGroups:
      - ""
    resources:
      - pods
      - services
      - services/finalizers
      - endpoints
      - persistentvolumeclaims
      - events
      - configmaps
      - secrets
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - apps
    resources:
      - deployments
      - daemonsets
      - replicasets
      - statefulsets
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
  - apiGroups:
      - monitoring.coreos.com
    resources:
      - servicemonitors
    verbs:
      - get
      - create
  - apiGroups:
      - apps
    resourceNames:
      - super-project
    resources:
      - deployments/finalizers
    verbs:
      - update
  - apiGroups:
      - ""
    resources:
      - pods
    verbs:
      - get
  - apiGroups:
      - apps
    resources:
      - replicasets
      - deployments
    verbs:
      - get
  - apiGroups:
      - automation.ocp.io
    resources:
      - '*'
    verbs:
      - create
      - delete
      - get
      - list
      - patch
      - update
      - watch
EOF

printf "Create deployment\n"
cat <<EOF | oc apply -f-
apiVersion: apps/v1
kind: Deployment
metadata:
  name: super-project-operator
  namespace: ${NAMESPCAE}
spec:
  replicas: 1
  selector:
    matchLabels:
      name: super-project-operator
  template:
    metadata:
      labels:
        name: super-project-operator
    spec:
      serviceAccountName: super-project
      containers:
        - name: ansible
          command:
            - /usr/local/bin/ao-logs
            - /tmp/ansible-operator/runner
            - stdout
          image: "${IMAGE}:${TAG}"
          imagePullPolicy: "Always"
          volumeMounts:
            - mountPath: /tmp/ansible-operator/runner
              name: runner
              readOnly: true
        - name: operator
          image: "${IMAGE}:${TAG}"
          imagePullPolicy: "Always"
          volumeMounts:
            - mountPath: /tmp/ansible-operator/runner
              name: runner
          env:
            - name: WATCH_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: OPERATOR_NAME
              value: "super-project"
            - name: ANSIBLE_GATHERING
              value: explicit
      volumes:
        - name: runner
          emptyDir: {}
EOF
