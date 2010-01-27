WeatherOrb
=========

An Arduino-powered ambient weather orb.


WHAT IS IT?
-----------

WeatherOrb is two parts:

1.  The first is a simple webapp that pulls the weather (Sydney-only, for now) from Yahoo Weather, via YQL. It then provides a simple web view of current and forecasted weather. It also provides dumbed-down xml of the weather for...

2.  An Arduino-powered ambient weather lamp. It uses the standard Arduino-board, along with an Ethernet shield, and a couple BlimkM color LEDs. The Arduino parses the above XML at regular intervals and changes the color of the LEDs to match the forecast.


WHAT IS NEXT?
-----------

*  I'd like to add some IP-based geo targeting so that we grab the local feed, rather than hard-coding the location.
*  I'm not happy with the temperature to color mapping.


LICENSE
------------

This software is licensed under the MIT license.