# Author::    Liam Bennett (mailto:lbennett@opentable.com)
# Copyright:: Copyright (c) 2013 OpenTable Inc
# License::   MIT

# == Class rundeck::config
#
# This private class is called from `rundeck` to manage the configuration
#
class rundeck::config {
  assert_private()

  $acl_policies                       = $rundeck::acl_policies
  $acl_template                       = $rundeck::acl_template
  $api_policies                       = $rundeck::api_policies
  $api_template                       = $rundeck::api_template
  $auth_template                      = $rundeck::auth_template
  $auth_types                         = $rundeck::auth_types
  $clustermode_enabled                = $rundeck::clustermode_enabled
  $database_config                    = $rundeck::database_config
  $execution_mode                     = $rundeck::execution_mode
  $file_default_mode                  = $rundeck::file_default_mode
  $file_keystorage_dir                = $rundeck::file_keystorage_dir
  $file_keystorage_keys               = $rundeck::file_keystorage_keys
  $vault_keystorage_prefix            = $rundeck::vault_keystorage_prefix
  $vault_keystorage_url               = $rundeck::vault_keystorage_url
  $vault_keystorage_approle_approleid = $rundeck::vault_keystorage_approle_approleid
  $vault_keystorage_approle_secretid  = $rundeck::vault_keystorage_approle_secretid
  $vault_keystorage_approle_authmount = $rundeck::vault_keystorage_approle_authmount
  $vault_keystorage_authbackend       = $rundeck::vault_keystorage_authbackend
  $grails_server_url                  = $rundeck::grails_server_url
  $group                              = $rundeck::group
  $gui_config                         = $rundeck::gui_config
  $java_home                          = $rundeck::java_home
  $jvm_args                           = $rundeck::jvm_args
  $kerberos_realms                    = $rundeck::kerberos_realms
  $key_password                       = $rundeck::key_password
  $key_storage_type                   = $rundeck::key_storage_type
  $keystore                           = $rundeck::keystore
  $keystore_password                  = $rundeck::keystore_password
  $log_properties_template            = $rundeck::log_properties_template
  $mail_config                        = $rundeck::mail_config
  $manage_default_admin_policy        = $rundeck::manage_default_admin_policy
  $manage_default_api_policy          = $rundeck::manage_default_api_policy
  $overrides_dir                      = $rundeck::overrides_dir
  $package_ensure                     = $rundeck::package_ensure
  $preauthenticated_config            = $rundeck::preauthenticated_config
  $projects                           = $rundeck::projects
  $projects_description               = $rundeck::projects_description
  $projects_organization              = $rundeck::projects_organization
  $projects_storage_type              = $rundeck::projects_storage_type
  $quartz_job_threadcount             = $rundeck::quartz_job_threadcount
  $rd_loglevel                        = $rundeck::rd_loglevel
  $rd_auditlevel                      = $rundeck::rd_auditlevel
  $rdeck_config_template              = $rundeck::rdeck_config_template
  $rdeck_home                         = $rundeck::rdeck_home
  $manage_home                        = $rundeck::manage_home
  $rdeck_profile_template             = $rundeck::rdeck_profile_template
  $rdeck_override_template            = $rundeck::rdeck_override_template
  $realm_template                     = $rundeck::realm_template
  $rss_enabled                        = $rundeck::rss_enabled
  $security_config                    = $rundeck::security_config
  $security_role                      = $rundeck::security_role
  $server_web_context                 = $rundeck::server_web_context
  $service_logs_dir                   = $rundeck::service_logs_dir
  $service_name                       = $rundeck::service_name
  $service_restart                    = $rundeck::service_restart
  $session_timeout                    = $rundeck::session_timeout
  $ssl_enabled                        = $rundeck::ssl_enabled
  $ssl_port                           = $rundeck::ssl_port
  $ssl_keyfile                        = $rundeck::ssl_keyfile
  $ssl_certfile                       = $rundeck::ssl_certfile
  $storage_encrypt_config             = $rundeck::storage_encrypt_config
  $truststore                         = $rundeck::truststore
  $truststore_password                = $rundeck::truststore_password
  $user                               = $rundeck::user
  $security_roles_array_enabled       = $rundeck::security_roles_array_enabled
  $security_roles_array               = $rundeck::security_roles_array

  File {
    owner  => $user,
    group  => $group,
    mode   => $file_default_mode,
  }

  $framework_config = deep_merge($rundeck::params::framework_config, $rundeck::framework_config)
  $auth_config      = deep_merge($rundeck::params::auth_config, $rundeck::auth_config)

  $logs_dir       = $framework_config['framework.logs.dir']
  $rdeck_base     = $framework_config['rdeck.base']
  $projects_dir   = $framework_config['framework.projects.dir']
  $properties_dir = $framework_config['framework.etc.dir']
  $plugin_dir     = $framework_config['framework.libext.dir']

  File[$rdeck_home] ~> File[$framework_config['framework.ssh.keypath']]

  if $manage_home {
    file { $rdeck_home:
      ensure  => directory,
    }
  } elsif ! defined_with_params(File[$rdeck_home], { 'ensure' => 'directory' }) {
    fail('when rundeck::manage_home = false a file definition for the home directory must be included outside of this module.')
  }

  if $rundeck::sshkey_manage {
    file { $framework_config['framework.ssh.keypath']:
      mode    => '0600',
    }
  }

  file { $rundeck::service_logs_dir:
    ensure  => directory,
  }

  ensure_resource(file, $projects_dir, { 'ensure' => 'directory' })
  ensure_resource(file, $plugin_dir, { 'ensure'   => 'directory' })

  # Checking if we need to deploy realm file
  #  ugly, I know. Fix it if you know better way to do that
  #
  if 'file' in $auth_types or 'ldap_shared' in $auth_types or 'active_directory_shared' in $auth_types {
    $_deploy_realm = true
  } else {
    $_deploy_realm = false
  }

  if $_deploy_realm {
    file { "${properties_dir}/realm.properties":
      content => template($realm_template),
      require => File[$properties_dir],
    }
  }

  if 'file' in $auth_types {
    $active_directory_auth_flag = 'sufficient'
    $ldap_auth_flag = 'sufficient'
  } else {
    if 'active_directory' in $auth_types {
      $active_directory_auth_flag = 'required'
      $ldap_auth_flag = 'sufficient'
    }
    elsif 'active_directory_shared' in $auth_types {
      $active_directory_auth_flag = 'requisite'
      $ldap_auth_flag = 'sufficient'
    }
    elsif 'ldap_shared' in $auth_types {
      $ldap_auth_flag = 'requisite'
    }
    elsif 'ldap' in $auth_types {
      $ldap_auth_flag = 'required'
    }
  }

  if 'active_directory' in $auth_types or 'ldap' in $auth_types {
    $ldap_login_module = 'JettyCachingLdapLoginModule'
  }
  elsif 'active_directory_shared' in $auth_types or 'ldap_shared' in $auth_types {
    $ldap_login_module = 'JettyCombinedLdapLoginModule'
  }
  file { "${properties_dir}/jaas-auth.conf":
    content => template($auth_template),
    require => File[$properties_dir],
  }

  file { "${properties_dir}/log4j.properties":
    content => template($log_properties_template),
    require => File[$properties_dir],
  }

  if $manage_default_admin_policy {
    rundeck::config::aclpolicyfile { 'admin':
      acl_policies   => $acl_policies,
      owner          => $user,
      group          => $group,
      properties_dir => $properties_dir,
      template_file  => $acl_template,
    }
  }

  if $manage_default_api_policy {
    rundeck::config::aclpolicyfile { 'apitoken':
      acl_policies   => $api_policies,
      owner          => $user,
      group          => $group,
      properties_dir => $properties_dir,
      template_file  => $api_template,
    }
  }

  if ($rdeck_profile_template) {
    file { "${properties_dir}/profile":
      content => template($rdeck_profile_template),
      require => File[$properties_dir],
    }
  }

  if ($rdeck_override_template) {
    file { "${overrides_dir}/${service_name}":
      content => template($rdeck_override_template),
    }
  }

  contain rundeck::config::global::framework
  contain rundeck::config::global::project
  contain rundeck::config::global::rundeck_config
  contain rundeck::config::global::file_keystore

  Class['rundeck::config::global::framework']
  -> Class['rundeck::config::global::project']
  -> Class['rundeck::config::global::rundeck_config']
  -> Class['rundeck::config::global::file_keystore']

  if $ssl_enabled {
    contain rundeck::config::global::ssl
    Class['rundeck::config::global::rundeck_config']
    -> Class['rundeck::config::global::ssl']
  }

  create_resources(rundeck::config::project, $projects)

  if versioncmp( $package_ensure, '3.0.0' ) < 0 {
    class { 'rundeck::config::global::web':
      security_role                => $security_role,
      session_timeout              => $session_timeout,
      security_roles_array_enabled => $security_roles_array_enabled,
      security_roles_array         => $security_roles_array,
      require                      => Class['rundeck::install'],
    }
  }

  if !empty($kerberos_realms) {
    file { "${properties_dir}/krb5.conf":
      owner   => $user,
      group   => $group,
      mode    => '0640',
      content => template('rundeck/krb5.conf.erb'),
      require => File[$properties_dir],
    }
  }
}
