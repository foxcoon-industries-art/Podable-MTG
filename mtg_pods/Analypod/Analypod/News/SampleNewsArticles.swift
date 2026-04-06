import Foundation


public struct jsonExample: Decodable {
    public var jsonString : String {
        let _ = print("inside json string")
        return """
    {
    "articles": [
        {
            "id": "550e8401-e29c-41d5-a717-446655440006",
            "date": "2025-12-30T10:00:00.000000",
            "headline": {
                "title": "The Quiet Kill",
                "image": {
                    "url": "https://foxcoon-industries.ca/news/img/quiet_v3.png",
                    "caption": "Be the silent threat at the table"
                }
            },
            "content": [
                {
                    "type": "header",
                    "text": "The Best Win You Will Ever Have"
                },
                {
                    "type": "body",
                    "text": "There is a specific kind of Commander win that stays with you longer than any other. It is not the one where you swung for twenty with a packed board. It is not the one where you topdecked the perfect card at the perfect moment. It is the one where you sat there, turn after turn, and nobody at the table looked twice at you — and then you won. Quietly. The other article in this series talked about how hard it is to correctly read the quiet player. This is the other side of that conversation. Not how to spot them. How to be one."
                },
                {
                    "type": "header",
                    "text": "Boring Is a Strategy"
                },
                {
                    "type": "body",
                    "text": "Most players think of playing conservatively as something you do when you are behind or when you do not have a good answer yet. That framing is exactly backwards. Playing boring is not a defensive posture. It is an offensive one. It is an active, deliberate choice to make every play as unremarkable as possible — not weak, not passive, but genuinely unremarkable. Before every decision, the quiet player is running a second calculation alongside the obvious one. The first question is: does this advance my game plan. The second question is: does this make someone look at me. Most of the time, those two questions have very different answers."
                },
                {
                    "type": "body",
                    "text": "That second question is what separates players who win quietly from players who just win. Playing a ramp spell when you also have a removal spell in hand might be the right call even if the removal feels more urgent in the moment — because the ramp spell is boring and the removal spell is not. Nobody comments when you play a ramp spell. Nobody re-evaluates you after you play one. The removal spell tells the table exactly what you are paying attention to, and who you consider important. The quiet player does not avoid impactful plays. They avoid plays that draw a reaction."
                },
                {
                    "type": "header",
                    "text": "What They See and What They Do Not"
                },
                {
                    "type": "body",
                    "text": "Here is the asymmetry that makes the whole thing work. What your opponents can see is your board: your creatures, your permanents, your lands. What they cannot see is your hand. They do not know about the combo piece you drew three turns ago. They do not know that you have had enough in hand to finish the game since turn nine and have simply been choosing not to. A player who has been quietly drawing cards for twelve turns while the table fought over someone else's board might have more options than everyone else combined — and none of it is visible. Card advantage — the distance between how many cards you have seen and how many they know about — is the most dangerous thing you can build, and it looks like nothing at all."
                },
                {
                    "type": "header",
                    "text": "Let Someone Else Be the Problem"
                },
                {
                    "type": "body",
                    "text": "The single best thing that can happen to a quiet player is for someone else at the table to be loud. A big board. An aggressive attack sequence. A flashy spell that resets everyone's priorities. That player is a gift. They are doing the one thing you are deliberately not doing: making themselves the center of attention. All you have to do is keep being boring while someone else is being interesting. This is where politics and quiet play meet. The players who win these games are almost always the ones who were helpful earlier — who answered a threat for someone else, who made a deal that looked generous. That is not generosity. That is camouflage. Political capital buys time, and time is the one resource that quiet strategies need most."
                },
                {
                    "type": "header",
                    "text": "The Flip"
                },
                {
                    "type": "body",
                    "text": "Every quiet strategy has one critical moment: the turn where you stop being unremarkable and start being lethal. Getting the timing right on that turn is the difference between a quiet win and a quiet loss. The natural instinct is to flip the switch the moment you are able to finish the game. That instinct is almost always wrong. If you reveal your win condition one turn too early, every other player at the table sees it at the same time — and in a four-player game, three people working together can usually stop one. The right moment to flip is one turn before you think it is safe. When the table is still looking somewhere else. When nobody has any reason to be watching you. You get one quiet turn. Then the game ends."
                },
                {
                    "type": "header",
                    "text": "Find Your Quiet Killer"
                },
                {
                    "type": "body",
                    "text": "If you want to find which of your commanders are natural fits for this style, Podable can do the heavy lifting. Pull up your commander stats and look at win rate — but cross-reference it with total commander damage dealt. A commander that wins consistently but deals very little commander damage is not winning by being the aggressor. It is winning by being the last one standing after everyone else has been dealt with. Those are your quiet killers. The average game length for those commanders tends to run longer too — nobody rushes to stop a threat they cannot see. And if you have been playing one of these commanders and getting eliminated in the early game, it might not be the deck. It might be that you have been playing it too loudly."
                }
            ],
            "poll": {
                "question": "How do you usually try to fly under the radar?",
                "options": [
                    "🤫",
                    "🏗️",
                    "🎭",
                    "🃏",
                    "🤷"
                ]
            }
        },
        {
            "id": "550e8401-e29c-41d5-a717-446655440005",
            "date": "2025-12-30T09:00:00.000000",
            "headline": {
                "title": "The Threat Assessment Trap",
                "image": {
                    "url": "https://foxcoon-industries.ca/news/img/threat_v3.png",
                    "caption": "Who is -really- the threat?"
                }
            },
            "content": [
                {
                    "type": "header",
                    "text": "The Question Every Player Asks"
                },
                {
                    "type": "body",
                    "text": "At every Commander table, at some point in the game, someone says it: Wait... who's actually the biggest threat right now? It is the single most asked strategic question in a four-player game. It is also the question that gets answered wrong more often than almost any other. Threat assessment is the skill of correctly reading which player is genuinely the most dangerous at any given moment. It is where Commander games are quietly won and lost. And almost no one does it as well as they think they do."
                },
                {
                    "type": "header",
                    "text": "Why Four Players Changes Everything"
                },
                {
                    "type": "body",
                    "text": "In a two-player game, threat assessment is trivial. Your opponent is the threat. End of story. Commander shatters this completely. With three or four players, the threat is a moving target that shifts based on context, timing, table politics, and a dozen variables that change every single turn. A player with a full battlefield of creatures might not be the real threat if their deck is a slow-burn life-gain shell. Meanwhile the player sitting quietly behind a single mana rock might be one card away from assembling a lethal combo. The person who correctly reads the difference between these two situations (and adjusts their decisions around it) is almost always the one still standing when the dust settles."
                },
                {
                    "type": "header",
                    "text": "The Board-State Trap"
                },
                {
                    "type": "body",
                    "text": "The most common threat-assessment mistake is anchoring entirely on what is visible on the battlefield. Big creatures, a sprawl of artifacts, an active planeswalker — these are loud signals, and our brains are wired to treat loud signals as the most important ones. But Commander is full of games where the scariest-looking board belonged to the least dangerous player. Combo decks can win from an empty board in a single turn. Stax players do not need a single permanent to lock everyone out. A player who has been quietly drawing cards for twelve turns straight might have more answers in hand than everyone else at the table combined. Board state is real information. It is just not the only information, and treating it as though it is is where most threat reads go sideways."
                },
                {
                    "type": "header",
                    "text": "What the Data Actually Shows"
                },
                {
                    "type": "body",
                    "text": "Here is where it gets interesting for anyone who has been logging games. Pull up your commander stats and look at win rates filtered by deck archetype. Cross-reference the commanders that win most often with how threatening they typically look on the board at the midpoint of the game. The patterns that come back are almost never what your gut told you at the table. Slow, reactive decks that looked harmless consistently outperform the flashy aggro boards that drew everyone's attention. Data does not care about what looked scary. It only records who actually won. And over time, the gap between what felt threatening and what was actually dangerous turns out to be one of the most consistent blind spots in Commander."
                },
                {
                    "type": "header",
                    "text": "There Is No Formula"
                },
                {
                    "type": "body",
                    "text": "If you came here hoping for a five-step checklist that cracks threat assessment wide open, here is the uncomfortable truth: there is not one. The right read changes based on the decks at the table, the tendencies of the people playing them, where you are in the game, and half a dozen other variables that are in constant motion. What does exist (and what the best Commander players actually do) is stay curious. They do not commit to a single threat read and hold it all game. They update it every turn, every time something changes. They ask not just 'who looks dangerous' but 'who is closest to winning' and 'who has the fewest obstacles between them and the end of the game.' That second question is almost always the better one. The best tool you have is not a formula. It is paying attention and being willing to change your mind."
                }
            ],
            "poll": {
                "question": "How do you usually decide who the biggest threat is?",
                "options": [
                    "👀",
                    "📊",
                    "🎯",
                    "🤷",
                    "💬"
                ]
            }
        },
        {
            "id": "550e8401-e29c-41d5-a717-446655440004",
            "date": "2025-11-15T00:11:59.659454",
            "headline": {
                "title": "The Art of Reading the Table",
                "image": {
                    "url": "https://foxcoon-industries.ca/news/img/the-table-v2.png",
                    "caption": "Never judge a table by its cover"
                }
            },
            "content": [
                {
                    "type": "header",
                    "text": "Commander Is a People Game"
                },
                {
                    "type": "body",
                    "text": "Of all the strategic dimensions in Magic: The Gathering Commander, none is more consistently undervalued than politics. New players optimize their mana curves and card-advantage engines, but the players who truly dominate at the Commander table are the ones who master the art of reading (and shaping) the social dynamics happening around them. Raw card power gets you halfway. Reading the table gets you the rest of the way."
                },
                {
                    "type": "header",
                    "text": "What Does 'Reading the Table' Actually Mean?"
                },
                {
                    "type": "body",
                    "text": "Reading the table means paying attention to everything that isn't on the battlefield. It's noticing when a player hesitates before attacking. It's picking up on the tone shift when someone says 'I'm not a threat.' It's understanding that the player who just got their commander destroyed is either quietly rebuilding or quietly planning revenge and knowing which one before they play their next card."
                },
                {
                    "type": "body",
                    "text": "None of this information appears on any card. It lives in the room, in the pauses, in the way players frame their decisions out loud. Commander is the only format in Magic where this layer of the game matters as much as the mechanical one."
                },
                {
                    "type": "header",
                    "text": "The Threat Hierarchy"
                },
                {
                    "type": "body",
                    "text": "Every Commander game has an invisible threat hierarchy that shifts constantly. The player closest to winning is always the primary target, in theory. In practice, the player who looks closest to winning is the target. This distinction matters enormously. A player with a subtle, long-game strategy can often fly under the radar for far longer than one with an obvious board presence, even if the subtle strategy is actually more dangerous."
                },
                {
                    "type": "body",
                    "text": "Podable's bracket system helps calibrate this. If you're watching a Bracket 4 deck develop, you already know the pilot intends to overrun the table. That information shapes your threat assessment before the first card is played. Pay attention to what players declared during Pod setup — it tells you a great deal about their intent before a single mana symbol is spent."
                },
                {
                    "type": "header",
                    "text": "The Deal and the Stab"
                },
                {
                    "type": "body",
                    "text": "Deals in Commander are inherently temporary. Every agreement has an implicit expiration date: the moment one player no longer benefits from it. The best politicians at the table aren't the ones who never break deals, they're the ones who break them at exactly the right moment, and more importantly, the ones who can recover their reputation quickly afterward."
                },
                {
                    "type": "body",
                    "text": "The key is timing. Breaking a deal too early turns the whole table against you. Breaking it too late means you missed your window. The sweet spot is usually right after the game state has shifted enough that your betrayal feels justified to the other players watching. 'I had no choice' is the most powerful sentence at the Commander table... but only if it's believable."
                },
                {
                    "type": "header",
                    "text": "Common Mistakes"
                },
                {
                    "type": "body",
                    "text": "The single biggest political mistake in Commander is telegraphing your intentions. If every player at the table knows you're about to win, they will coordinate to stop you, often successfully. Keeping your win condition ambiguous, or making it look further away than it actually is, buys you the critical extra turn you need. The best wins in Commander are the ones no one saw coming."
                },
                {
                    "type": "body",
                    "text": "Another common mistake is burning political capital on small plays. If you call in a favour to save one creature on your third turn, that's favour you can't spend later when it actually matters. Save your influence for the moments that shape the outcome of the game. Early-game politics should be about positioning, not about winning individual exchanges."
                },
                {
                    "type": "header",
                    "text": "Track It with Podable"
                },
                {
                    "type": "body",
                    "text": "Here's what's fascinating: the players who consistently win Commander games aren't always the ones with the best decks. They're the ones who read the table well. Podable's game logs and commander statistics can help you identify patterns over time. If you notice that a particular commander wins more often in higher bracket pods, it might not be raw card power driving those wins. It might be that the pilot simply plays the political game better when the stakes are higher. Next time you log a pod, pay attention to the social dynamics alongside the board state. You might be surprised at what the data reveals."
                }
            ]
        },
        {
            "id": "550e8401-e29c-41d5-a717-446655440003",
            "date": "2025-10-31T00:11:59.659454",
            "headline": {
                "title": "Interpreting the Pod Map",
                "image": {
                    "url": "https://i.imgur.com/QP5oeRo.png",
                    "caption": "So many charts rolled up into one image"
                }
            },
            "content": [
                {
                    "type": "header",
                    "text": "Unlock the Hidden Patterns in Your Games"
                },
                {
                    "type": "body",
                    "text": "Podable's advanced analytics transform raw game data into actionable strategic insights. Each visualization reveals different aspects of your gameplay, helping you understand not just what happened, but why it happened and how to improve."
                },
                {
                    "type": "header",
                    "text": "See the Story of Every Game"
                },
                {
                    "type": "body",
                    "text": "The Pod Map displays turn-by-turn intensity for each player, revealing when games are won and lost. Each cell represents one turn, colored by the type and amount of damage dealt during that turn. If the map shows you being eliminated during high-intensity periods, you may need better defensive options or threat assessment skills. Predicting when opponents tend to be aggressive can give you a reactive advantage when deciding whether to hold removal or a counter."
                },
                {
                    "type": "header",
                    "text": "Separate Facts from Fiction"
                },
                {
                    "type": "body",
                    "text": "The Turn Percentage chart shows the amount of time each player took over the game. Tapping the players segment will highlight their row in the Pod Map. The Turn Percentage gives you definitive proof for determining if your pod has a durdler or turn hog."
                },
                {
                    "type": "header",
                    "text": "The Waterfall of Pain"
                },
                {
                    "type": "body",
                    "text": "The chart entitled Loss of Life shows the evolution of players' life totals as the game progresses. Starting life of 40 is at the top and for each turn, a segment gets added below to describe the amount of life lost. When the blood waterfall hits the bottom (zero life) it indicates the player has been eliminated. Commander damage is plotted using the color of the player who dealt it."
                },
                {
                    "type": "header",
                    "text": "Commander Companion Cube"
                },
                {
                    "type": "body",
                    "text": "The Commander Companion Cube chart shows the amount of commander damage dealt by each player at the intersection between players. The more damage, the more the partitions will push into their side. Diagonal players are shown in the center of the chart, with their damages being shown cross corner in the center. Each Pod should have a unique shape for their Companion Cube, so play on and see what you'll get!"
                }
            ]
        },
        {
            "id": "550e8401-e29c-41d5-a717-446655440002",
            "date": "2025-10-17T00:11:59.659454",
            "headline": {
                "title": "A Vibe Check on Brackets",
                "image": {
                    "url": "https://64.media.tumblr.com/tumblr_m4pfdwBYYA1qia2dho1_1280.jpg",
                    "caption": "How players feel when they want to play MTG"
                }
            },
            "content": [
                {
                    "type": "header",
                    "text": "Motivation"
                },
                {
                    "type": "body",
                    "text": "Wizards of the Coast recently released the bracket system for Magic: The Gathering commander players to assign their decks into. The goal was to provide a categorical framework for deck selection based on various limitations (such as a set number of powerful cards) and to encourage players to start on equal footing with each other."
                },
                {
                    "type": "body",
                    "text": "What the company has failed to communicate is that this issue isn't about the power level of the decks themselves, but rather about the intent of the people playing them. The most important part of which bracket a deck falls into is HOW the decks' pilot intends to use the deck in a pod. The brackets should NOT be thought of as a scale from low power to high power, but as distinctly separate categories of play. The root of the error was defining the brackets categories with numbers, which misleads players back into the false narrative of power levels."
                },
                {
                    "type": "body",
                    "text": "Podable is an app for commander players, built by commander players. As such, we want to accurately relay (for better or for worse) the ways actual ways Magic players are using the bracket system. Here, we discuss a more intuitive way on how to think of brackets and why player intent ultimately determines which bracket to assign a deck into."
                },
                {
                    "type": "header",
                    "text": "Bracket 1 - Story Time"
                },
                {
                    "type": "body",
                    "text": "Bracket 1 focuses on thematic world-building through the thoughtful choice of cards. Magic: The Gathering is a game built on a plethora of fantasy worlds, each with extensive backstories. Players are incentivized to weave a coherent story with each card they play. This bracket is commonly misinterpreted as being for weak cards and weak decks. This is untrue. Powerful decks can be built from thematic card sets; it just takes creativity to unlock that power. In Bracket 1, players focus on sharing an experience rather than trying to win at all costs."
                },
                {
                    "type": "header",
                    "text": "Bracket 2 - Doing the Thing"
                },
                {
                    "type": "body",
                    "text": "Bracket 2 is for players who wish to test out their deck-building and piloting skills. Decks in this bracket are usually ones made from a new pile or have typically undergone several revisions since the last played game. Players should be eager to get their deck to do the thing.  Whether thats trying to complete a new unseen combo or testing out a novel synergy between pet cards, this bracket aims to value exploration of strategy over well known cases. If everyone in the pod gets a chance to do the thing, the game is considered a success."
                },
                {
                    "type": "header",
                    "text": "Bracket 3 - Standard Game"
                },
                {
                    "type": "body",
                    "text": "Bracket 3 seems to be the default choice for anyone who just wants to play the game. Here is where players begin to focus their aim towards winning the game. Decks with varied gameplay and strategy emerge as a result of players trying to one-up each other during the pod. A set number of Game Changer cards can be included within the deck, but these are not a requirement to participate and enjoy playing in this bracket."
                },
                {
                    "type": "header",
                    "text": "Bracket 4 - Friendly Fight"
                },
                {
                    "type": "body",
                    "text": "Bracket 4 is for players who haven't yet realized that dying in a game does NOT mean they die in real life. As a result, this bracket is for players who keep grudges against others and are unlikely to have developed the ability to lose with grace. Games involve building a large board state and overrunning the table at once. Decks played in this bracket are highly tuned (net-decked) and packed with many powerful game-changing cards."
                },
                {
                    "type": "header",
                    "text": "Bracket 5 - Race to Win"
                },
                {
                    "type": "body",
                    "text": "Bracket 5 (commonly known as cEDH - Competitive Commander) focuses on the most strategy of all: winning. Players often avoid this bracket during pre-game talks, only to find themselves playing in this bracket without knowing it. The intent of players here is work together to prevent any one player from obtaining the win through alternative methods. Games typically revolve around politics/deal-making and usually last for only a few turns. A common strategy is to cheat out a win as fast as possible using the most broken cards ever printed over all of Magic's history. These powerful cards are often extremely expensive, and as a result, players fill their decks with proxy (counterfeit) cards. Podable takes no ethical stance on proxy usage, rather just acknowledges that it is what it is."
                },
                {
                    "type": "header",
                    "text": "Are Brackets the Solution?"
                },
                {
                    "type": "body",
                    "text": "Podable can keep track of bracket ratings and analyzes their relative accuracy by letting opponents rate the other decks in the pod after the game finishes. This bracket disparity can be seen with the Vibe Check chart found in the Brackets Statistics page. While Wizards of the Coast has set forth a good first step, the real solution is probably comes from the use of data-driven insights about actual deck performances."
                },
                {
                    "type": "header",
                    "text": "Enhancing Bracket Accuracy with Vibes"
                },
                {
                    "type": "body",
                    "text": "Players assign the bracket the feel their deck falls into during Pod setup. After the match, players rate each other's decks and assign the bracket they felt their opponents actually tried to play in. This dual Vibes rating aims to reduces bias by highlighting whether your bracket choice matches reality. When a player wins a game, the bracket they chose becomes the ground truth for their deck. This implies that game winner's are more in tune with the level at which they claim to play at. However, opponents also get a say in the bracket ratings each other's decks. This bracket accuracy is measured as a percentage of the number of opponents who assign the same bracket to the winners deck as the winner did. This secondary accuracy metric helps players gauge whether their initial rating was fair. If a player notices that opponents consistently rate their deck differently, it may be worth reflecting on why and possibly choosing a different bracket for next time."
                }
            ]
        },
        {
            "id": "550e8400-e29b-41d4-a716-446655440001",
            "date": "2025-10-01T00:11:59.659454",
            "headline": {
                "title": "Welcome to Podable!",
                "image": {
                    "url": "https://i.imgur.com/cI9uGt2.jpeg",
                    "caption": "We are glad you can join us!"
                }
            },
            "content": [
                {
                    "type": "header",
                    "text": "Bring your Pod's Casts to Life!"
                },
                {
                    "type": "body",
                    "text": "Podable keeps track of your pod. Here's the rundown of each section."
                },
                {
                    "type": "header",
                    "text": "New Pod"
                },
                {
                    "type": "body",
                    "text": "Supplement in-person games of Magic: the Gathering with the New Pod. Log game states like Life Totals, Commander Damage, Turn Duration, and Deck Brackets."
                },
                {
                    "type": "header",
                    "text": "Data"
                },
                {
                    "type": "body",
                    "text": "Podable bundles up all the statistical values by Commander, Bracket, and Turn Order. Cool charts about your data can be found in Data."
                },
                {
                    "type": "body",
                    "text": "Download and update Podable's list of usable Commanders from Scryfall. Make sure to do this before starting any New Pods and after each new set release!"
                },
                {
                    "type": "header",
                    "text": "Mega Magic News"
                },
                {
                    "type": "body",
                    "text": "Read up on the latest Mega Magic News stories written by community members. Find tips and tricks on how to use Podable here too!"
                },
                {
                    "type": "header",
                    "text": "Histoy"
                },
                {
                    "type": "body",
                    "text": "Game summaries of each of your Pods can be found in the History section. Share your Pods with the community, and export the best games to share with your friends!"
                }
            ],
            "poll": {
                "question": "News articles have polls for user feedback! How did this do?",
                "options": [
                    "🤷",
                    "📊",
                    "📰",
                    "🤔",
                    "👍"
                ]
            }
        }
    ]
    }
    """
    }
}
