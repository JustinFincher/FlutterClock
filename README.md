![](images/banner.jpeg)

# Conic Clock

> Conic Clock is a dynamic clock written in Flutter. It is a project by me (ZHENG HAOTIAN / Justin Fincher) for the [Flutter Clock challenge](https://flutter.dev/clock). 

The conic shadow angle represents seconds. On the top left and bottom right there are hour and minute indicators, while on top right there is the weather and bottom left be the location.  
The color scheme would adapt depending on the time, weather, and temperature. For example, at 6:00 it would be sunrise (pink + pale blue), in rainstorm weather it would be darker, at a high temperature color would be more vibrant, etc.  
Please see the Youtube video below for more info.

# Youtube

[See a demo video](https://www.youtube.com/watch?v=PzMQfQRS5k8)

# Screenshots

| Time | Weather | Screenshot |
|------|---------|------------|
|12:53|Clear|![](images/1.jpeg)|
|18:33|Clear|![](images/2.jpeg)|
|21:34|Clear|![](images/3.jpeg)|
|23:53|Clear|![](images/4.jpeg)|
|03:59|Clear|![](images/5.jpeg)|
|06:02|Clear|![](images/6.jpeg)|
|08:20|Clear|![](images/7.jpeg)|
|12:12|Clear|![](images/8.jpeg)|
|15:23|Clear|![](images/9.jpeg)|


# Design Philosophy
I view Lenovo Smart Clock, along with other smart clocks like Google Home Hub (which I do have one), as 'ambient' devices, because:

- they are usually stationary (because clocks need to be at a fixed position for people to access info easily)
- they work passively (proactive feedback only happens either when the device was activated by voice commands or physical interactions on screen, other than that it is just a clock)
- Ideally, they are always-on (so there need to be smooth transitions, no sudden changes to catch unnecessary attentions, and flashy weather effects like lighting are certainly forbidden because no one wants this when they were about to sleep in a dim room)

So the clockface needs to both reflect and blend in with the environment. A conic clock fits well:

- The conic shadow is in constant rotation, 60 seconds per lap. It is predictable, reliable, easy to understand, with no learning cost.
- The color scheme is in constant updates, but only in a progressive manner. The clockface, as a view component, could not know when would the data provider refresh the clock, thus any interpolation methods with a fixed duration would cause unexpected behaviors.  Instead, the lerp function respects the previous momentum to give a natural feeling about dynamic color changes.
- The color scheme is an effective representation of the environment the clock is in, including temperature, weather, and time. Using the HSV color model, all these factors can be interpreted into changes in hue, saturation, value. For example:
  - Night -> overall darker colors -> V-
  - Day -> overall lighter colors -> V+
  - Hot -> overall more vibrant colors -> S+
  - Foggy -> still bright, but colors faded -> S- V+
  - Rainstorm -> darker, but with contrast -> S+ V-
- The usage of masks on texts is to both maintain the readability of the texts and, at the same time, the 'ambient' feel.
  - Time is the most important element, so hour-and-minute indicators would be at both top left and bottom right. At any time there would be at least one location where the time is visible.
  - Weather and location, compared to time, are not that important, so each of them is respectively visible for 30 seconds in one lap, with fade-in-and-out animations, as I do not want these to mess with the overall beauty of the conic.

# Tips

For debugging, [conic_clock.dart](conic_clock/lib/conic_clock.dart) has a property called `_lightYearMode`. Use it as a time lapse toggle, time would be 3000x faster than normally it would be.
