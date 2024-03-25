import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:zmoney/fukk_widgets/play_google.dart';

class TextCycleWidget extends StatefulWidget {
  const TextCycleWidget({super.key});

  @override
  TextCycleWidgetState createState() => TextCycleWidgetState();
}

class TextCycleWidgetState extends State<TextCycleWidget> {
  final List<String> translatedtexts2 = [
    "How Much?",
    "This is a game",
    "It should test your logic",
    "Enter numbers",
    "Try to enter numbers",
    "Guess a number",
    "For the Win",
    "Challenge Accepted",
    "Unveil the Secret",
    "Dare to Dream",
    "Beyond the Horizon",
    "Unlock the Mystery",
    "Explore the Unknown",
    "Embrace the Adventure",
    "Solve the Puzzle",
    "Discover the Magic",
    "Journey Awaits",
    "The Final Countdown",
    "Race Against Time",
    "Capture the Moment",
    "Seize the Day",
    "A Leap of Faith",
    "Break the Silence",
    "Reach for the Stars",
    "Ignite the Flame",
    "Chase the Sunset",
    "Beyond Dreams",
    "Whispers of the Old World",
    "Echoes of the Future",
    "Dance with Destiny",
    "Sing the Blues Away",
    "Ride the Winds of Change",
    "A Twist of Fate",
    "Unravel the Mystery",
    "Defy the Odds",
    "Across the Universe",
    "Beneath the Surface",
    "Against All Odds",
    "Among the Stars",
    "Navigate the Storm",
    "Light Up the Dark",
    "Colors of the Wind",
    // New additions
    "Tales of the Forgotten",
    "Glimpses of Tomorrow",
    "Echoes from Beyond",
    "Paths Less Traveled",
    "Shadows of the Past",
    "Whispers in the Night",
    "Legends Untold",
    "Realms Uncharted",
    "Secrets of the Deep",
    "Visions of Eternity",
    "Mysteries Unveiled",
    "Dreams Unleashed",
    "Journeys Unbegun",
    "Horizons New and Old",
    "Voices of the Ancients",
    "Light Beyond the Shadows",
    "Riddles of the Stars",
    "Tides of Time",
    "Sagas of the Sea",
    "Worlds Within Worlds",
    "Guardians of the Lost",
    "Keepers of the Flame",
    "Masters of Illusion",
    "Architects of Fate",
    "Wanderers in the Void",
    "Harbingers of Hope",
    "Sorcerers of the Night",
    "Enigmas of Existence",
    "Chronicles of the Brave",
    "Ballads of the Bards",
    "Silence Speaks Louder Than Words",
    "The Tapestry of Time Weaves Its Own Tales",
    "In the Garden of Thought, Ideas Bloom Like Flowers",
    "Stars Are the Dreams of the Universe",
    "Time Is a River That Flows Through the Soul",
    "Memory Is the Diary We All Carry About With Us",
    "Life Is the Art of Drawing Without an Eraser",
    "Words Are the Shadows of Our Feelings",
    "The Mind Is a Universe Bound by Your Horizons",
    "Courage Is the Companion of Wisdom",
    "A Journey of a Thousand Miles Begins in the Heart",
    "Every Ending Is a New Beginning Seen From a Different Perspective",
    "Truth Is a Mirror That Scatters in Many Pieces",
    "The Heartbeat of the Earth Sings in Silence",
    "Nature Is the Greatest Artist and the Universe Her Canvas",
    "The Wisdom of the Ages Is Whispered by the Wind",
    "Hope Is the Beacon of the Soul",
    "Freedom Is the Canvas of the Mind",
    "Imagination Is the Only Weapon in the War Against Reality",
    "Knowledge Is a Treasure, but Practice Is the Key to It",
    "Change Is the Constant Riddle of the Universe",
    "Curiosity Is the Compass That Leads Us to Discovery",
    "Patience Is the Guardian of Time",
    "Reflection Is the Lantern of the Heart",
    "Compassion Is the Language the Deaf Can Hear and the Blind Can See",
    "Understanding Is the Bridge Between Worlds",
    "Forgiveness Is the Fragrance the Violet Sheds on the Heel That Has Crushed It",
    "The Universe Whispers Its Secrets to Those Who Dare to Listen",
    "Life Is an Echo; What You Send Out Comes Back",
    "Resilience Is Woven From the Threads of Trial",
    "Love Is the Only Force Capable of Transforming an Enemy Into a Friend",
    "Action Is the Foundational Key to All Success",
    "The Beauty of the World Lies in the Diversity of Its People",
    "Integrity Is the Seed of Achievement Rooted in the Soil of Character",
    "Creativity Is the Dance of the Intellect Among Ideas",
    "Unity Is Strength, Where There Is Teamwork and Collaboration, Wonderful Things Can Be Achieved",
    "Gratitude Turns What We Have Into Enough",
    "Each Moment Is a Place You've Never Been",
    "Adventure Awaits Those Who Dare to Dream",
    "Empathy Is Seeing With the Eyes of Another, Listening With the Ears of Another, and Feeling With the Heart of Another",
    "Perseverance Is Not a Long Race; It Is Many Short Races One After the Other",
    "Life Is Not Measured by the Number of Breaths We Take, but by the Moments That Take Our Breath Away",
    "Courage Doesn't Always Roar. Sometimes Courage Is the Quiet Voice at the End of the Day Saying, 'I Will Try Again Tomorrow.'",
    "The Only Limit to Our Realization of Tomorrow Will Be Our Doubts of Today.",
  ];

  int _currentIndex = 0;

  void _updateText() {
    setState(() {
      if (_currentIndex == translatedtexts2.length - 1) {
        // This is the last text in the list, time to unlock an achievement
        PlayGoogle.unlockAchievement("CgkIipShgv8MEAIQFQ");

        // Reset the index or do something else if needed
        _currentIndex = 0; // Example: Resetting the index
      } else {
        // Increment the index normally
        _currentIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldAllowWrap = translatedtexts2[_currentIndex].length > 40;

    return GestureDetector(
      onTap: _updateText,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: AutoSizeText(
            translatedtexts2[_currentIndex],
            minFontSize: 20,
            maxFontSize: 40,
            maxLines: shouldAllowWrap ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            key: ValueKey<int>(_currentIndex),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
