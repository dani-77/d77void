"""
lock_screen.py
--------------

This module provides a class to manage lock screen settings for Qtile.

Classes:
    AppSettingsLockScreen:
        Manages lock screen settings including command, timeout, font, joke settings, and blur type.
"""


class AppSettingsLockScreen:
    command = "swaylock"
    timeout = 1
    font = ""
    font_size = 17
    quote_font_path = ""
    quote_font_size = 17
    joke_providers = "reddit"
    quote_foreground_color = "#fff"
    quote_text_color = "#000"
    icanhazdad_joke_url = ""
    reddit_joke_url = "https://www.reddit.com/r/ProgrammerDadJokes.json"
    blurtype = "0x5"

    def __init__(self, **kwargs):
        """
        Initializes the AppSettingsLockScreen with optional keyword arguments.

        Args:
            **kwargs: Arbitrary keyword arguments to initialize the lock screen settings.
        """
        self.command = kwargs.get("command", self.command)
        self.timeout = kwargs.get("timeout", str(self.timeout))
        self.font = kwargs.get("font", self.font)
        self.font_size = int(kwargs.get("font_size", str(self.font_size)))
        self.quote_font_path = kwargs.get("quote_font_path", self.quote_font_path)
        self.quote_font_size = int(
            kwargs.get("quote_font_size", str(self.quote_font_size))
        )
        self.joke_providers = kwargs.get("joke_providers", self.joke_providers).split(
            ","
        )
        self.quote_foreground_color = kwargs.get(
            "quote_foreground_color", self.quote_foreground_color
        )
        self.quote_text_color = kwargs.get("quote_text_color", self.quote_text_color)
        self.icanhazdad_joke_url = kwargs.get(
            "icanhazdad_joke_url", self.icanhazdad_joke_url
        )
        self.reddit_joke_url = kwargs.get("reddit_joke_url", self.reddit_joke_url)
        self.blurtype = kwargs.get("blurtype", self.blurtype)
