# Battery Planner

Plan your day hour by hour and see the exact moment your phone battery dies. My data is now saved on the phone with shared_preferences, so nothing is lost when the app closes, and it shows the current temperature in Kigali from the Open-Meteo API.

**Mini project chosen:** Battery Planner (Mobile Programming, Session 4)

## Features

- Day from 7:00 to 23:00, starting at 100% battery
- Each activity drains the battery (video 12%, games 15%, chat 5%, music 6%, idle 2%) and charging adds 20%, kept between 0 and 100 every hour
- Battery shown as a number and a bar per hour, red under 20%
- Banner: "Dies at HH:00" or "Survives with N% left"; hours after death shown as dead
- Tap an hour to change its activity or turn charging on or off
- Plan is saved with shared_preferences and is still there after closing the app
- Live Kigali temperature from the Open-Meteo API, with an error message and Retry button when there is no internet

## Screenshots

![Before closing](screenshots/proof.png)

### Extra screenshot

<!-- Put one more screenshot here, for example: ![Edit screen](screenshots/edit.png) -->

## Think questions

**Does when you charge matter, or only how much?**

Yes, when you charge matters, not just how much. My two test plans both charge for 3 hours, so both add up to 60% on paper. But charging at 7:00, 8:00 and 9:00 dies at 20:00, while charging at 8:00, 11:00 and 12:00 survives with 2% left. The reason is the 100% limit. In the first plan the battery is still at or near 100% in those hours, so part of every charge is thrown away (about 18% in total). In the second plan I charge when the battery is already lower, so all of the 60% is actually kept and it gets me to the end of the day.


**Why must the battery be kept between 0 and 100 every hour, and not just at the end?**

Because the battery can't go above 100 or below 0 at any moment, and what happens in one hour changes the next one. If I only fixed the number at the end, the extra charge I wasted at the start would be counted as saved, and the answer would be wrong. Also, once the battery reaches 0 the phone is dead, so charging later can't bring it back. If I let it go negative and only clamped at the end, a later charge could cancel the negative number and the app would say the phone survives when it already died. Clamping every hour keeps each hour's value true.

