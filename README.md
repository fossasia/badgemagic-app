<img height="200px" src="./docs/images/app_icon.png" align="right" />

# Badge Magic
[![Join the chat at https://gitter.im/fossasia/badge-magic](https://badges.gitter.im/fossasia/badge-magic.svg)](https://gitter.im/fossasia/badge-magic?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
![Github](https://img.shields.io/github/license/fossasia/badgemagic-app?logo=github)

**Python Library to program via desktop https://github.com/fossasia/led-name-badge-ls32**

**Magically Create Text and Draw Cliparts on LED Name Badges using Bluetooth**

The Badge Magic Android app lets you create moving text and draw clipart for LED name badges. The app provides options to portray names, cliparts, and simple animations on the badges. For the org.fossasia.badgemagic.data transfer from the smartphone to the LED badge it uses Bluetooth. The project is based on the work of [Nilhcem](https://github.com/Nilhcem).

## Get Stable Versions

<a href='https://apps.apple.com/us/app/badge-magic/id6740176888'><img align='center' height='55' src='./docs/images/appstore_badge.svg'></a>
<a href='https://play.google.com/store/apps/details?id=org.fossasia.badgemagic'><img align='center' height='55' src='./docs/images/google_play_badge.png'></a>
<a href='https://f-droid.org/en/packages/org.fossasia.badgemagic/'><img align='center' alt='Get it on F-Droid' src='./docs/images/fdroid_badge.png' height="55"/></a>

## Get Beta Versions (Built from the latest code)

<a href='https://testflight.apple.com/join/h6tHnYGK'><img align='center' height='55' src='./docs/images/testflight.png'></a>
<a href='https://play.google.com/apps/testing/org.fossasia.badgemagic'><img align='center' height='55' src='./docs/images/google_play_badge.png'></a>

## Download

* [Latest Release Build](https://github.com/fossasia/badgemagic-app/raw/apk/badge-magic-development-release.apk) in the apk branch

## Permissions
* **Bluetooth**: For sending org.fossasia.badgemagic.data to the badge.
* **Storage**: For storing and saving badges.

Up to Android version 11
* **GPS Location**: This has been the standard set by Android for use with Bluetooth Low Energy (BLE) devices. For more information, please read the notes on [Android website](https://source.android.com/devices/bluetooth/ble).

## Communication

Please talk to us on the badge-magic [Gitter channel here](https://gitter.im/fossasia/badge-magic).

## Translations

Translators can support the project on Weblate here: https://hosted.weblate.org/projects/fossasia/badge-magic-app/

## Available Devices

There are a number of devices with Bluetooth on the market. As far as we can tell they are mostly from the same manufacturer. When you get a org.fossasia.badgemagic.device ensure it comes with Bluetooth. There are devices that don't support Bluetooth. These are not supported in the app currently.
* Get one from the [FOSSASIA Shop here](https://fossasia.com/product/led-badge/)

## Screenshots

<table>
  <tr>
    <td><img src="https://github.com/fossasia/badgemagic-app/blob/fastlane-android/metadata/android/en-US/images/phoneScreenshots/Pixel_6-1_home_screen.png" width="1080"/></td>
    <td><img src="https://github.com/fossasia/badgemagic-app/blob/fastlane-android/metadata/android/en-US/images/phoneScreenshots/Pixel_6-2_text_badge.png" width="1080"/></td>
    <td><img src="https://github.com/fossasia/badgemagic-app/blob/fastlane-android/metadata/android/en-US/images/phoneScreenshots/Pixel_6-3_emoji_badge.png" width="1080"/></td>
    <td><img src="https://github.com/fossasia/badgemagic-app/blob/fastlane-android/metadata/android/en-US/images/phoneScreenshots/Pixel_6-4_inverted_emoji_badge.png" width="1080"/></td>
  </tr>
  <tr>
    <td><img src="https://github.com/fossasia/badgemagic-app/blob/fastlane-android/metadata/android/en-US/images/phoneScreenshots/Pixel_6-5_saved_badges.png" width="1080"/></td>
    <td><img src="https://github.com/fossasia/badgemagic-app/blob/fastlane-android/metadata/android/en-US/images/phoneScreenshots/Pixel_6-6_saved_badges_clicked.png" width="1080"/></td>
    <td colspan="2">
      <img src="https://github.com/fossasia/badgemagic-app/blob/fastlane-android/metadata/android/en-US/images/phoneScreenshots/Pixel_6-7_draw_badge.png" width="2146"/>
    </td>
  </tr>
</table>

## Reverse-Engineering Bluetooth LE Devices

Security in Bluetooth LE devices is optional, and many cheap products you can find on the market are not secured at all. This applies to our Bluetooth LED Badge. While this could lead to some privacy issues, this can also be a source of fun, especially when you want to use an LED Badge in a different way. It also makes it easy for us to get started with the development of a Free and Open Source Android app.

As we understand how the Bluetooth LED badge works, converting a text to multiple byte arrays, we can send using the Bluetooth LE APIs. An indepth blog post about reverse-engineering the Bluetooth community [is here](http://nilhcem.com/iot/reverse-engineering-bluetooth-led-name-badge).

The implementation in the Android app consists of manipulating bits. That may be tricky. A single bit error and nothing will work, plus it will be hard to debug. For those reasons, and since the specs are perfectly clear the reverse engineer Gautier Mechling strongly recommends to start writing unit tests before the code implementation.

## Branch Policy

We have the following branches

 * **development**: All development goes on in this branch. If you're making a contribution, you are supposed to make a pull request to _development_. PRs to development branch must pass a build check on CI/CD.
 * **apk**: This branch contains many apk files, that are automatically generated on the merged pull request a) debug apk b) release apk
    - There are multiple files in the apk branch of the project, this branch consists of all the APK files and other files that are relevant when an APK is generated.
    - Once a pull request is merged, the previous APK branch is deleted and a new APK branch is created.
    - If a PR is merged in development branch then the new APKs for the development branch are generated whereas the APKs corresponding to the master branch are not regenerated and simply the previously generated files are added.
* **version**: This branch stores the version information for the APKs (versionName and versionCode). This is used in our workflows for automatic versioning wherein the next version information is automatically fetched from this branch and used for building APKs.
* **fastlane***: These branches contain information and metadata used by fastlane to automate deployment.
* **pr-screenshots**: This branch stores screenshots for every open pull request, which are shown in comments in every pull request.

## Contributions Best Practices

Please read FOSSASIA's [Best Practices](https://blog.fossasia.org/open-source-developer-guide-and-best-practices-at-fossasia/) before contributing. Please help us follow the best practice to make it easy for the reviewer as well as the contributor. We want to focus on the code quality more than on managing pull request ethics. Here are some basics:

* Single commit per pull request
* For writing commit messages please read the [CommitStyle.md](docs/commitStyle.md).
* Follow uniform design practices. The design language must be consistent throughout the app.
* The pull request will not get merged until and unless the commits are squashed. In case there are multiple commits on the PR, the commit author needs to squash them and not the maintainers cherrypicking and merging squashes.
* If the PR is related to any front end change, please attach relevant screenshots in the pull request description.
* Before you join development, please set up the project on your local machine, run it and go through the application completely. Press on any button you can find and see where it leads to. Explore.
* If you would like to work on an issue, drop in a comment at the issue. If it is already assigned to someone, but there is no sign of any work being done, please free to drop in a comment and start working on it.

## Release Process

### Beta Release Flow
* All merged pull requests into the development branch are automatically included in the beta version of the app.
* The beta builds are automatically pushed to:
  - Google Play Store (Beta Track)
  - Apple TestFlight (iOS Beta)
This allows contributors and testers to try out the latest features and verify stability before the app is released to all users.

### Production Release Flow
* A new GitHub release (using the "Releases" tab) is the trigger for publishing a production version.
* When a GitHub release is created:
  - The latest beta APK or iOS build is promoted to the production track on the respective app stores.
  - No additional code changes are made unless specified.
This ensures that the version tested in beta is the exact one released to the public.

### Notes
* Please ensure all features and fixes are tested and merged into development before a GitHub release is created.
* Versioning and changelogs should be updated accordingly.
* If any hotfixes are required post-release, they should go through the same flow (PR → beta → release).

## Dev Container usage

Opening this repository in VSCode, GitHub Codespaces or another supported editor/IDE will allow the repository to be opened in a [Dev Container](https://containers.dev/).

The Dev Container contains all necessary dependencies and tools required to build, run and debug flutter applications.

### How to connect via `adb`

:warning: In case `adb` is already installed and running on the host it may need to be stopped before continuing.

This Dev Container allows several different methods of connecting to a device via `adb`:

#### Entirely from inside the container (USB pass-through)

:information_source: **Windows** and **MacOS** need a working **USB/IP** setup. Read more in the official [Docker Desktop documentation](https://docs.docker.com/desktop/features/usbip/) and in this [blog post](https://blog.golioth.io/usb-docker-windows-macos/).

The Dev Container bind-mounts `/dev/bus/usb/` and sets the correct access controls for a seamless integration.  \
Enable [USB debugging](https://developer.android.com/tools/adb#Enabling) on your phone and try to find it via:

```bash
adb devices
```
If it shows up, everything is ready and you can run `flutter run` to push a development version of the app onto your device.

#### Using the host's `adb` server

If `adb` is already installed on the host, the tools in the Dev Container can be configured to use the host's `adb` server:

1. Ensure the `adb` server is listening on **all interfaces**
    1. If that is not the case, kill and restart it: `adb kill-server && adb -a server` (the `-a` instructs it to listen on all interfaces).
1. Set or export the following environment variable before executing `adb` or `flutter run`: `ADB_SERVER_SOCKET=tcp:host.docker.internal:5037`
1. You should now be able to list the devices connected via USB to the host

#### Wireless connection

Android 11 and higher support wireless debugging. Check out the [documentation](https://developer.android.com/tools/adb#wireless-android11-command-line) for more information.  \
For this mode it is required that both the workstation and the device are on the **same network**.

:information_source: This also works when developing inside **GitHub Codespaces**. In that case you can bring your device and the Codespace onto the same network by installing WireGuard, Tailscale or another overlay/mesh network on both the Codespace and your device.

Enable Wireless debugging as per the [documentation](https://developer.android.com/tools/adb#wireless-android11-command-line), then **pair** `adb pair <IP>:<PORT>` and **connect** `adb connect <IP>:<PORT>` and you should be able to find your device via `adb devices`.


## LICENSE

The application is licensed under the [Apache License 2.0](/LICENSE). Copyright is owned by FOSSASIA and its contributors.

## OTHER BADGE APPS

* [LED Python App](https://github.com/fossasia/led-name-badge-ls32)
