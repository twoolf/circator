# A Fastlane action to set XCode to use provisioning profiles from environment variables.
# This is useful because XCode developers often set provisioning profiles manually in XCode
# and then commit the pbxproj to a git repository (e.g., to add new files).
# We can then reset the pbxproj.
#
# This action is based off the update_project_provisioning action:
# https://github.com/fastlane/fastlane/blob/master/lib/fastlane/actions/update_project_provisioning.rb
#
module Fastlane
  module Actions
    module SharedValues
    end

    class SetProjectProvisioningEnvVarAction < Action
      ROOT_CERTIFICATE_URL = "http://www.apple.com/appleca/AppleIncRootCertificate.cer"
      def self.run(params)
        # assign folder from parameter or search for xcodeproj file
        folder = params[:xcodeproj] || Dir["*.xcodeproj"].first

        # validate folder
        project_file_path = File.join(folder, "project.pbxproj")
        raise "Could not find path to project config '#{project_file_path}'. Pass the path to your project (not workspace)!".red unless File.exist?(project_file_path)

        # download certificate
        unless File.exist?(params[:certificate])
          UI.message("Downloading root certificate from (#{ROOT_CERTIFICATE_URL}) to path '#{params[:certificate]}'")
          require 'open-uri'
          File.open(params[:certificate], "w") do |file|
            file.write(open(ROOT_CERTIFICATE_URL, "rb").read)
          end
        end

        target_filter = params[:target_filter] || params[:build_configuration_filter]
        configuration = params[:build_configuration]

        # manipulate project file
        UI.success("Going to update project '#{folder}' with UUID")
        require 'xcodeproj'

        project = Xcodeproj::Project.open(folder)
        project.targets.each do |target|
          if !target_filter || target.product_name.match(target_filter) || (target.respond_to?(:product_type) && target.product_type.match(target_filter))
            UI.success("Updating target #{target.product_name}...")
          else
            UI.important("Skipping target #{target.product_name} as it doesn't match the filter '#{target_filter}'")
            next
          end

          target.build_configuration_list.build_configurations.each do |build_configuration|
            config_name = build_configuration.name
            if !configuration || config_name.match(configuration)
              UI.success("Updating configuration #{config_name}...")
            else
              UI.important("Skipping configuration #{config_name} as it doesn't match the filter '#{configuration}'")
              next
            end

            build_configuration.build_settings["PROVISIONING_PROFILE"] = "$(#{params[:env_var]})"
          end
        end

        project.save

        # complete
        UI.message("Successfully updated project settings in'#{params[:xcodeproj]}'")
      end

      def self.description
        "Update projects code signing settings from your profisioning profile"
      end

      def self.details
        [
          "This action sets an XCode project's provisioning profile UUIDs to use environment variables.",
          "The `target_filter` value can be used to only update code signing for specified targets",
          "The `build_configuration` value can be used to only update code signing for specified build configurations of the targets passing through the `target_filter`",
          "Example Usage is the WatchKit Extension or WatchKit App, where you need separate provisioning profiles",
          "Example: `set_project_provisioning_env_var(xcodeproj: \"..\", env_var: \"WATCH_UUID\", target_filter: \".*WatchKit App.*\")`"
        ].join("\n")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                                       env_name: "FL_PROJECT_PROVISIONING_PROJECT_PATH",
                                       description: "Path to your Xcode project",
                                       optional: true,
                                       verify_block: proc do |value|
                                         raise "Path to xcode project is invalid".red unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :env_var,
                                       env_name: "FL_PROJECT_PROVISIONING_PROFILE_ENV_VAR",
                                       description: "Provisioning profile environment variable",
                                       default_value: "UUID"),
          FastlaneCore::ConfigItem.new(key: :target_filter,
                                       env_name: "FL_PROJECT_PROVISIONING_PROFILE_TARGET_FILTER",
                                       description: "A filter for the target name. Use a standard regex",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :build_configuration_filter,
                                       env_name: "FL_PROJECT_PROVISIONING_PROFILE_FILTER",
                                       description: "Legacy option, use 'target_filter' instead",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :build_configuration,
                                       env_name: "FL_PROJECT_PROVISIONING_PROFILE_BUILD_CONFIGURATION",
                                       description: "A filter for the build configuration name. Use a standard regex. Applied to all configurations if not specified",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :certificate,
                                       env_name: "FL_PROJECT_PROVISIONING_CERTIFICATE_PATH",
                                       description: "Path to apple root certificate",
                                       default_value: "/tmp/AppleIncRootCertificate.cer")
        ]
      end

      def self.authors
        ["yanif"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include? platform
      end
    end
  end
end
