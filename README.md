# Badge Magic

**Magically Create Text and Draw Cliparts on LED Name Badges using Bluetooth**

The goal of the Badge Magic app is to let you create moving text and draw cliparts for to LED name badges. With the app we want to provide options to portray names, cliparts and simple animations on the badges. For the data transfer from the smartphone to the LED badge we use Bluetooth.

## Permissions

- **Bluetooth**: For sending data to the badge.
- **GPS Location**: This has been the standard set by ios for use with Bluetooth Low Energy (BLE) devices. For more information, please read the notes on [ios website](https://source.ios.com/devices/bluetooth/ble).
- **Storage**: For storing and saving badges.

## Communication

Please talk to us on the badge-magic [Gitter channel here](https://gitter.im/fossasia/badge-magic).

## Available Devices

There are a number of devices with Bluetooth on the market. To ensure you have a compatible badge get it on the FOSSASIA store here:

- [FOSSASIA Shop here](https://fossasia.com/product/led-badge/)

## Reverse-Engineering Bluetooth LE Devices

Security in Bluetooth LE devices is optional, and many cheap products you can find on the market are not secured at all. This applies to our Bluetooth LED Badge. While this could lead to some privacy issues, this can also be a source of fun, especially when you want to use an LED Badge in a different way. It also makes it easy for us to get started with the development of a Free and Open Source ios app.

As we understand how the Bluetooth LED badge works, converting a text to multiple byte arrays, we can send using the Bluetooth LE APIs. An indepth blog post about reverse-engineering the Bluetooth community [is here](http://nilhcem.com/iot/reverse-engineering-bluetooth-led-name-badge).

The implementation in the ios app consists of manipulating bits. That may be tricky. A single bit error and nothing will work, plus it will be hard to debug. For those reasons, and since the specs are perfectly clear we recommend to start writing unit tests before the code implementation.

## Running / Development

To run the project on iOS you need installed XCode and have a phisical device.

- Generate the native part of the app using the command:
  ```bash
    yarn ios --configuration=Debug --device
  ```
- Open `BadgeMagic.xcworkspace` in Xcode, then in the 'Signing and Capabilities' section, set up Development Team and Bundle Identifier.
- Check if the physical build destination is set up on the physical device (this may be useful to remove Push Notifications). If you have a different Apple ID between Xcode and your device, you need to allow the device to accept the Apple ID in Settings -> Device Management.
- If you still can't open the app, try deleting the `ios\.xcode.env.local` file. It may help :) [Bug description] (https://github.com/facebook/react-native/issues/39903#issuecomment-1847591269).

## Branch Policy

We have the following branches

- **development** All development goes on in this branch. If you're making a contribution, you are supposed to make a pull request to _development_. PRs to development branch must pass a build checks.
- **main** This contains shipped code. After significant features/bugfixes are accumulated on development, we make a version update and make a release.

## Contributions Best Practices

Please read FOSSASIA's [Best Practices](https://blog.fossasia.org/open-source-developer-guide-and-best-practices-at-fossasia/) before contributing. Please help us follow the best practice to make it easy for the reviewer as well as the contributor. We want to focus on the code quality more than on managing pull request ethics. Here are some basics:

- Single commit per pull request
- Follow uniform design practices. The design language must be consistent throughout the app.
- The pull request will not get merged until and unless the commits are squashed. In case there are multiple commits on the PR, the commit author needs to squash them and not the maintainers cherrypicking and merging squashes.
- If the PR is related to any front end change, please attach relevant screenshots in the pull request description.
- Before you join development, please set up the project on your local machine, run it and go through the application completely. Press on any button you can find and see where it leads to. Explore.
- If you would like to work on an issue, drop in a comment at the issue. If it is already assigned to someone, but there is no sign of any work being done, please free to drop in a comment and start working on it.

## LICENSE

The application is licensed under the [Apache License 2.0](/LICENSE). Copyright is owned by FOSSASIA and its contributors.
