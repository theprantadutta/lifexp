# Animation Assets

This directory contains Lottie animation files for the LifeXP app celebrations.

## Required Animation Files

Place the following Lottie JSON files in this directory:

### Celebration Animations
- `level_up.json` - Level up celebration with sparkles and confetti
- `achievement_unlock.json` - Achievement unlock with badge reveal animation
- `task_complete.json` - Task completion success animation
- `streak_fire.json` - Streak milestone with fire/flame effects
- `celebration.json` - Generic celebration animation

## Animation Guidelines

- Keep file sizes under 500KB for optimal performance
- Use 60fps for smooth animations
- Duration should be 2-4 seconds
- Include loop points for repeating animations
- Use bright, celebratory colors that match the app theme

## Sources for Lottie Animations

You can find free Lottie animations at:
- [LottieFiles](https://lottiefiles.com/)
- [Rive](https://rive.app/)
- Create custom animations with After Effects + Bodymovin

## Fallback Behavior

If animation files are missing, the app will show fallback icons:
- Level up: Trophy icon
- Achievement: Star icon  
- Task complete: Check circle icon
- Streak: Fire icon
- Generic: Celebration icon