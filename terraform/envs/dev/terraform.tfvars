cluster_name    = "prj01-dev"
cluster_version = "1.33"

# Cluster admin is granted to the SSO administrator role (console and kubectl
# access from my workstation) and to the CI apply role (so pipeline runs can
# manage the cluster). The role that runs terraform apply also keeps admin via
# enable_cluster_creator_admin_permissions in the module.
admin_access_role_arns = [
  "arn:aws:iam::149536464688:role/aws-reserved/sso.amazonaws.com/eu-west-1/AWSReservedSSO_AWSAdministratorAccess_fd679cd3b5a2c3a7",
  "arn:aws:iam::149536464688:role/prj01-ci-apply",
]
