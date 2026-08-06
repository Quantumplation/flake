{ ... }: {
  programs.awscli = {
    enable = true;
    settings = {
      "default" = {
        "region" = "us-east-2";
      };
      "profile dev" = {
        "sso_session" = "pi";
        "sso_account_id" = "529991308818";
        "sso_role_name" = "AWSAdministratorAccess";
        "region" = "us-east-2";
      };
      "profile prod" = {
        "sso_session" = "pi";
        "sso_account_id" = "705895683800";
        "sso_role_name" = "AWSAdministratorAccess";
        "region" = "us-east-2";
      };
      "profile shared" = {
        "sso_session" = "pi";
        "sso_account_id" = "113073460856";
        "sso_role_name" = "AWSAdministratorAccess";
        "region" = "us-east-2";
      };
      "profile management" = {
        "sso_session" = "pi";
        "sso_account_id" = "583028480321";
        "sso_role_name" = "AWSAdministratorAccess";
        "region" = "us-east-2";
      };
      "profile founder" = {
        "sso_session" = "pi";
        "sso_account_id" = "890625032284";
        "sso_role_name" = "AWSAdministratorAccess";
        "region" = "us-east-2";
      };
      "profile cardano-tom" = {
        "sso_session" = "pi";
        "sso_account_id" = "978007052758";
        "sso_role_name" = "AWSAdministratorAccess";
        "region" = "us-east-2";
      };
      "sso-session pi" = {
        "sso_start_url" = "https://d-9a672d8c7d.awsapps.com/start/#";
        "sso_region" = "us-east-2";
        "sso_registration_scopes" = "sso:account:access";
      };
    };
  };
}
