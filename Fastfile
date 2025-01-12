# This file contains the fastlane.tools configuration
# You can find the documentation at https://docs.fastlane.tools
#
# For a list of all available actions, check out
#
#     https://docs.fastlane.tools/actions
#
# For a list of all available plugins, check out
#
#     https://docs.fastlane.tools/plugins/available-plugins
#

# Uncomment the line if you want fastlane to automatically update itself
# update_fastlane

default_platform(:ios)

platform :ios do
  before_all do
    setup_ci
  end

  lane :setupCertificates do
    bundle_id = CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)
    runner_temp = ENV['RUNNER_TEMP'] || '/tmp'
    keychain_path = File.join(runner_temp, 'app-signing.keychain-db')
    keychain_password = ENV['KEYCHAIN_PASSWORD']
    
    sync_code_signing(
      api_key_path: './fastlane.json',
      type: "appstore",
      readonly: true,
    )

    update_code_signing_settings(
      use_automatic_signing: false,
      path: "Runner.xcodeproj",
      bundle_identifier: bundle_id,
      code_sign_identity: "iPhone Distribution",
      profile_name: Actions.lane_context[SharedValues::MATCH_PROVISIONING_PROFILE_MAPPING][bundle_id]
    )
  end

  desc "Push a new beta build to TestFlight"
  lane :uploadToBeta do
    puts "Building and uploading to TestFlight"
    build_app(
      skip_build_archive: true,
      archive_path: "../build/ios/archive/Runner.xcarchive",
    )
    upload_to_testflight(
      api_key_path: './fastlane.json',
      groups: 'External Testing Group'
    )
  end
end
