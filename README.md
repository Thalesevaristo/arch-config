## First Things First: Update or Perish

After installing Arch WSL (and questioning your life choices), run:

```bash
pacman -Syu --noconfirm
```

This updates your repositories and packages.

## Summoning the Almighty Curl

Next, install curl with:

```bash
pacman -S curl git --noconfirm
```

## The Magic Script

Download our "slightly better than a napkin sketch" installation script:

```bash
git clone https://github.com/Thalesevaristo/Arch_config.git
```

## Release the Kraken!

Enter de folder, execute the script and pray to the Linux gods:

```bash
bash ./run.sh
```

Follow the on-screen prompts like they're sacred instructions from the Arch elders.

## The Aftermath

If all goes well (a big "if" in the Linux world), you'll have a "basic" configuration that's ready for actual use. Feel free to fork this masterpiece of digital duct tape and modify it to include packages you actually want.

Remember: this isn't just code, it's "art"... in the same way that a child's macaroni picture is "art" - made with love, but probably not going in the Louvre.
