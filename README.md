# Geppetto  v0.1.1
A lil midi control modulator.

Run `;install https://github.com/cachilders/geppetto.git` from maiden to install. Add your own device configs to `lib/devices` following the structure of the sample files. Be sure to back up your config files, and feel free to submit a PR with them to help out the next person.

Note that in Geppetto's current form only a single CC can be modulated on a single device at a time. Multiple devices and params are planned but time and tide and all that. 

- v0.1.1
  - Initial support for incoming and outgoing start and stop midi events.
  - Code refactors for future support of multiple devices
  - Reduced lfo resolution to ease broadcast of midi messages
  - Default selection of device input and disabling of navigation prior to initial selection
- v0.1.0
  - Basic functionality for a single device
