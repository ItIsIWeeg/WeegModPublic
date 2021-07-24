package;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import sys.FileSystem;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.tweens.FlxTween;
import Random;


#if windows
import Discord.DiscordClient;
#end

using StringTools;

class CharacterSelectState extends MusicBeatState
{
	var songs:Array<FreeplayState.SongMetadata> = [];
	var charList:Array<String> = [];
	var unloadedChars:Array<String> = [];
	var bg:FlxSprite;
	var newBG:FlxBackdrop;
	var selector:FlxText;
	var curSelected:Int = 0;
	public static var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	public static var chosenChar:String = "";

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	override function create()
	{
		FlxG.save.data.showedScene = false;
		var initSonglist = CoolUtil.coolTextFile(Paths.txt('characterSelectList'));
		var custSonglist = CoolUtil.coolTextFile('mods/characters/characters.txt');

		for (i in 0...initSonglist.length)
		{
			var data:Array<String> = initSonglist[i].split(':');
			songs.push(new FreeplayState.SongMetadata(data[0], 0, data[0]));
			charList.push(data[0]);
		}
		
		if (FlxG.save.data.unlockedBooba == true)
		{
			songs.push(new FreeplayState.SongMetadata('athena-goddess', 0, 'athena-goddess'));
			charList.push('athena-goddess');
		}
		if (FlxG.save.data.unlockedZuki == true)
		{
			songs.push(new FreeplayState.SongMetadata('kazuki', 0, 'kazuki'));
			charList.push('kazuki');
		}
		if (FlxG.save.data.unlockedSonic == true)
		{
			songs.push(new FreeplayState.SongMetadata('sonic', 0, 'sonic'));
			charList.push('sonic');
		}

		for (i in 0...custSonglist.length)
		{
			var data:Array<String> = custSonglist[i].split(':');
			songs.push(new FreeplayState.SongMetadata(data[0], 0, data[0]));
			charList.push(data[0]);
		}

		for (i in FileSystem.readDirectory(FileSystem.absolutePath("mods/characters")))
		{
			if (i.endsWith(".txt"))
                continue;
            unloadedChars.push(i);
		}

		for (i in 0...unloadedChars.length)
		{
			if (charList.contains(unloadedChars[i]))
				continue;
			songs.push(new FreeplayState.SongMetadata(unloadedChars[i], 0, unloadedChars[i]));
		}

		songs.push(new FreeplayState.SongMetadata('random', 2, 'face'));

		/* 
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		 */

		 FlxG.sound.playMusic(Paths.inst('choose your character'), 0.6);

		 #if windows
		 // Updating Discord Rich Presence
		 DiscordClient.changePresence("In the Freeplay Menu", null);
		 #end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		// LOAD MUSIC

		// LOAD CHARACTERS

		bg = new FlxSprite().loadGraphic(Paths.image('menuMacyDesat'));
		bg.color = 0xFFFFFFFF;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		//add(bg);

		add(newBG = new FlxBackdrop(Paths.image('cssBG')));
		newBG.velocity.set(-40, 40);

		switch(PlayState.SONG.song.toLowerCase())
		{
			case 'satin-panties' | 'high' | 'milf':
				curSelected = 2;
			case 'cocoa' | 'eggnog' | 'winter-horrorland':
				curSelected = 3;
			case 'senpai' | 'roses' | 'thorns':
				curSelected = 4;
			case 'spookeez' | 'south' | 'monster':
				curSelected = 1;
			default:
				curSelected = 0;
		}

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new FreeplayState.SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (controls.BACK)
		{
			if(PlayState.isStoryMode)
				FlxG.switchState(new StoryMenuState());
			else
				FlxG.switchState(new FreeplayState());
		}

		if (accepted)
		{
			var diffic = "";

			switch (curDifficulty)
			{
				case 0:
					diffic = '-easy';
				case 2:
					diffic = '-hard';
			}
			chosenChar = songs[curSelected].songName.toLowerCase();
			if (chosenChar == 'random')
			{
				//random time im sorry
				var randChar:Int = FlxG.random.int(0, (songs.length - 2));
				chosenChar = songs[randChar].songName.toLowerCase();
			}
			trace('CUR WEEK' + PlayState.storyWeek);
			FlxG.save.data.curChar = chosenChar;
			PlayState.activatedDebug = false;
			FlxG.save.data.storyBalls = 0;
			LoadingState.loadAndSwitchState(new PlayState());
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		#end

		switch (curDifficulty)
		{
			case 0:
				diffText.text = "EASY";
			case 1:
				diffText.text = 'NORMAL';
			case 2:
				diffText.text = "HARD";
		}
	}

	function changeSelection(change:Int = 0)
	{
		#if !switch
		// NGio.logEvent('Fresh');
		#end

		// NGio.logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		FlxTween.color(newBG, 0.15, newBG.color, FlxColor.fromString(Character.getColor(songs[curSelected].songName)));

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}
