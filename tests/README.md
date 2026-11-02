# Local tests

Run the movement and viewport tests from the repository root:

```sh
xvfb-run -a love tests
```

The integration test runs the actual game with an isolated save directory. It
needs a disposable copy because its test entry point wraps the game's main file:

```sh
tmp=$(mktemp -d)
cp -a . "$tmp/game"
mv "$tmp/game/main.lua" "$tmp/game/game-under-test.lua"
cp "$tmp/game/tests/integration/main.lua" "$tmp/game/main.lua"
mkdir "$tmp/data"
cd "$tmp/game"
XDG_DATA_HOME="$tmp/data" ALSOFT_DRIVERS=null xvfb-run -a -s '-screen 0 1280x800x24' love .
```
