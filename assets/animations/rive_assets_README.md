# Rive Animation Assets

This directory should contain Rive animation files (.riv) for the LifeXP app's interactive avatar system.

## Required Rive Files

Place the following Rive files in this directory:

### Avatar Animations
- `avatar.riv` - Main interactive avatar with state machine
  - State Machine: `AvatarStateMachine`
  - Inputs:
    - `idle` (Boolean) - Idle breathing animation
    - `levelUp` (Boolean) - Level up celebration
    - `strength` (Boolean) - Strength attribute gain effect
    - `wisdom` (Boolean) - Wisdom attribute gain effect  
    - `intelligence` (Boolean) - Intelligence attribute gain effect
    - `tap` (Boolean) - Tap interaction response

### Avatar Customization
- `avatar_customization.riv` - Avatar preview for customization
  - State Machine: `CustomizationStateMachine`
  - Inputs:
    - `preview` (Boolean) - Preview animation
    - `hair` (String) - Hair style selection
    - `eyes` (String) - Eye color selection
    - `clothing` (String) - Clothing selection
    - `accessory` (String) - Accessory selection

### Progress Animations
- `progress_bar.riv` - Animated progress bar
  - State Machine: `ProgressStateMachine`
  - Inputs:
    - `progress` (Number) - Progress value 0-1

### Attribute Effects
- `attribute_effects.riv` - Attribute gain visual effects
  - State Machine: `AttributeStateMachine`
  - Inputs:
    - `strength` (Boolean) - Strength effect trigger
    - `wisdom` (Boolean) - Wisdom effect trigger
    - `intelligence` (Boolean) - Intelligence effect trigger

## Animation Guidelines

### Avatar Design
- Character should be friendly and approachable
- Support multiple customization options
- Smooth idle breathing animation
- Celebratory level up animation with particles/glow
- Attribute-specific visual effects (strength = muscle flex, wisdom = brain glow, intelligence = sparkles)

### Technical Requirements
- Use state machines for interactive control
- Keep file sizes under 1MB each
- 60fps for smooth animations
- Proper input/output setup for Flutter integration

## Creating Rive Animations

1. Use [Rive Editor](https://rive.app/) to create animations
2. Set up state machines with the required inputs
3. Test animations in the Rive preview
4. Export as .riv files
5. Place in this directory

## Fallback Behavior

If Rive files are missing or fail to load, the app will show:
- Static avatar icons with level indicators
- Standard Flutter progress bars
- Simple icon-based attribute effects

This ensures the app remains functional even without custom animations.