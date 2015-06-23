# hubot-reload-scripts

[![](https://img.shields.io/npm/v/hubot-reload-scripts.svg?style=flat-square)](https://www.npmjs.com/package/hubot-reload-scripts)

Reloads scripts without restart. Loads new scripts too. (a fork version that works perfectly)

Fork from [the original](https://github.com/github/hubot-scripts/blob/master/src/scripts/reload.coffee) `reload.coffee` and @srobroek's [code](https://github.com/srobroek/hubot/blob/e543dff46fba9e435a352e6debe5cf210e40f860/src/robot.coffee).

## Installation

In your hubot project repo, run:

``` bash
npm install hubot-reload-scripts --save
```

Then add **hubot-reload-scripts** to your `external-scripts.json`:

``` json
[
  "hubot-reload-scripts"
]
```

## Usage

```
user>> hubot reload
hubot>> Reloaded all scripts
```
