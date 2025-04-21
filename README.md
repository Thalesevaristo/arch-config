# The "Oh No, I Installed Arch WSL" post-install Script 
So you've decided to brave the waters of Arch on WSL? Congratulations, brave digital explorer! This guide will help you survive the initial setup without losing your sanity (we make no promises beyond that point).

*If you don't like to suffer, just get this version, is way better implemented: https://github.com/typecraft-dev/crucible*

## First Things First: Update or Perish

After installing Arch WSL (and questioning your life choices), run:

```bash
pacman -Syu --no-confirm
```

This updates your repositories and packages.

## Summoning the Almighty Curl

Next, install curl with:

```bash
pacman -S curl --no-confirm
```

Because how else are you going to download things from the internet like it's 1999?

## The Magic Script

Download our "slightly better than a napkin sketch" installation script:

```bash
curl -o ./run.sh https://raw.githubusercontent.com/Thalesevaristo/Arch_config/refs/heads/main/Init.sh
```

## Release the Kraken!

Execute the script and pray to the Linux gods:

```bash
bash ./run.sh
```

Follow the on-screen prompts like they're sacred instructions from the Arch elders.

## The Aftermath

If all goes well (a big "if" in the Linux world), you'll have a "basic" configuration that's ready for actual use. Feel free to fork this masterpiece of digital duct tape and modify it to include packages you actually want.

Remember: this isn't just code, it's "art"... in the same way that a child's macaroni picture is "art" - made with love, but probably not going in the Louvre.
