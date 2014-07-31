<?php
/*------------------------------------------------------------*/
/* (1) Display
/*------------------------------------------------------------*/

/**
 * Default display for Twitter feed.
 *
 * @since 0.1.0
 */
function tweeple_display_default( $tweets, $options ) {
	echo tweeple_get_display_default( $tweets, $options );
}

/**
 * Get default display for Twitter feed.
 *
 * @since 0.1.0
 */
function tweeple_get_display_default( $tweets, $options = array() ) {

	$output = '';

	// Some basic error checking.
	if ( ! $tweets || ! is_array( $tweets ) || count( $tweets ) < 1 ) {
		return __('No tweets to display.', 'tweeple');
	}

	$output .= '<ul class="tweets">';

	// Loop through Tweets
	foreach( $tweets as $tweet ) {

		$output .= '<li class="tweet">';
		$output .= '<div class="tweet-wrap">';

		$text = apply_filters( 'tweeple_tweet_text', $tweet['text'], $tweet, $tweets, $options );
		$output .= sprintf( '<div class="tweet-text">%s</div>', $text );

		if ( tweeple_show_tweet_meta( $options ) ) {
			$output .= sprintf( '<div class="tweet-meta tweet-time">%s</div>', tweeple_get_tweet_meta( $tweet ) );
		}

		$output .= '</div><!-- .tweet-wrap (end) -->';
		$output .= '</li>';
	}

	$output .= '</ul>';

	return $output;

}

/**
 * Remove emoticons and pictographs from tweet that won't
 * display properly on the website.
 *
 * @since 0.9.2
 */
function tweeple_tweet_clean( $text ) {
	// Source: http://stackoverflow.com/questions/12807176/php-writing-a-simple-removeemoji-function#answer-20208095
	return preg_replace('/([0-9|#][\x{20E3}])|[\x{00ae}|\x{00a9}|\x{203C}|\x{2047}|\x{2048}|\x{2049}|\x{3030}|\x{303D}|\x{2139}|\x{2122}|\x{3297}|\x{3299}][\x{FE00}-\x{FEFF}]?|[\x{2190}-\x{21FF}][\x{FE00}-\x{FEFF}]?|[\x{2300}-\x{23FF}][\x{FE00}-\x{FEFF}]?|[\x{2460}-\x{24FF}][\x{FE00}-\x{FEFF}]?|[\x{25A0}-\x{25FF}][\x{FE00}-\x{FEFF}]?|[\x{2600}-\x{27BF}][\x{FE00}-\x{FEFF}]?|[\x{2900}-\x{297F}][\x{FE00}-\x{FEFF}]?|[\x{2B00}-\x{2BF0}][\x{FE00}-\x{FEFF}]?|[\x{1F000}-\x{1F6FF}][\x{FE00}-\x{FEFF}]?/u', '', $text );
}

/**
 * Default filter on tweet text.
 *
 * @since 0.1.0
 */
function tweeple_tweet_text_default( $text ) {

	// Removed any HTML special characters
	$text = htmlspecialchars_decode( $text, ENT_QUOTES );

	// Format URL's to be links - http://whatever.com
	$text = preg_replace('/\b([a-zA-Z]+:\/\/[\w_.\-]+\.[a-zA-Z]{2,6}[\/\w\-~.?=&%#+$*!]*)\b/i',"<a href=\"$1\" class=\"twitter-link\" target=\"_blank\">$1</a>", $text);

	// Format URL's to be links - http://www.whatever.com
	$text = preg_replace('/\b(?<!:\/\/)(www\.[\w_.\-]+\.[a-zA-Z]{2,6}[\/\w\-~.?=&%#+$*!]*)\b/i',"<a href=\"http://$1\" class=\"twitter-link\" target=\"_blank\">$1</a>", $text);

	// Format emails - you@yourmail.com
	$text = preg_replace("/\b([a-zA-Z][a-zA-Z0-9\_\.\-]*[a-zA-Z]*\@[a-zA-Z][a-zA-Z0-9\_\.\-]*[a-zA-Z]{2,6})\b/i","<a href=\"mailto://$1\" class=\"twitter-link\">$1</a>", $text);

	// Format hash tags as links - #whatever
	$text = preg_replace("/#(\w+)/", "<a class=\"twitter-link\" href=\"https://twitter.com/search?q=%23\\1\" target=\"_blank\">#\\1</a>", $text);

	// Format @username as links
	$text = preg_replace("/@(\w+)/", "<a class=\"twitter-link\" href=\"http://twitter.com/\\1\" target=\"_blank\">@\\1</a>", $text);

    return $text;
}

/**
 * Default meta for tweets.
 *
 * @since 0.1.0
 */
function tweeple_tweet_meta_default( $tweet ) {
	echo tweeple_get_tweet_meta_default( $tweet );
}

/**
 * Get default meta for tweets.
 *
 * @since 0.5.0
 */
function tweeple_get_tweet_meta_default( $tweet ) {
	$status_url = sprintf( 'https://twitter.com/%s/status/%s', $tweet['author'], $tweet['id_str'] );
	$time = date_i18n( get_option('date_format'), strtotime( $tweet['time'] ) );
	return sprintf( '<a href="%s" title="%s" target="_blank">%s</a>', $status_url, $time, $time );
}

/**
 * A fancier meta that could be used for tweets.
 * Currently not hooked to anything.
 *
 * @since 0.1.0
 */
function tweeple_tweet_meta_fancy( $tweet ) {
	echo tweeple_get_tweet_meta_fancy( $tweet );
}

/**
 * Get the fancier meta that could be used for tweets.
 * Currently not hooked to anything.
 *
 * @since 0.5.0
 */
function tweeple_get_tweet_meta_fancy( $tweet ) {

	// Status link
	$status_url = sprintf( 'https://twitter.com/%s/status/%s', $tweet['author'], $tweet['id_str'] );
	$time = date_i18n( get_option('date_format'), strtotime( $tweet['time'] ) );
	$time_link = sprintf( '<a href="%s" title="%s" target="_blank">%s</a>', $status_url, $time, $time );

	// Author link
	$author_url = sprintf( 'https://twitter.com/%s', $tweet['author'] );
	$author_link = sprintf( '<a href="%s" title="%s" target="_blank">%s</a>', $author_url, $tweet['author'], $tweet['author'] );

	// Final time stamp
	$timestamp = sprintf( '<span class="tweet-stamp">%s</span> <span class="tweet-author">%s %s</span>', $time_link, __( 'via', 'tweeple' ), $author_link );

	return '<div class="tweet-time tweet-meta">'.$timestamp.'</div>';

}

/**
 * Default display for "Tweet" element for Theme
 * Blvd Layout Builder.
 *
 * @since 0.4.0
 */
function tweeple_tweet_element_default( $tweets, $feed_options, $element_options ) {
	echo tweeple_get_tweet_element_default( $tweets, $feed_options, $element_options );
}

/**
 * Get default display for "Tweet" element for Theme
 * Blvd Layout Builder.
 *
 * @since 0.4.0
 */
function tweeple_get_tweet_element_default( $tweets, $feed_options, $element_options ) {

	if ( ! defined( 'TB_FRAMEWORK_VERSION' ) ) {
		return;
	}

	if ( ! $tweets ) {
		return __('No tweets to display.', 'tweeple');
	}

	$icon = $element_options['icon'];

	// Convert older icon option for those updating.
	if ( version_compare( TB_FRAMEWORK_VERSION, '2.2.0', '>=' ) ) {
		switch ( $icon ) {
			case 'message' :
				$icon = 'comment';
				break;
			case 'alert' :
				$icon = 'warning';
				break;
		}
	}

	$wrap_class = 'tb-tweet-wrapper';
	if ( $icon ) {
		$wrap_class .= ' has-icon';
	}

	$output = '';
	$count = 1;
	$max = apply_filters( 'tweeple_tweet_element_max_count', 1 ); // @todo Possibly make option later

	foreach ( $tweets as $tweet ) {

		if ( $count > $max )
			break;

		$output .= sprintf( '<div class="%s">', $wrap_class );

		if ( $icon ) {
			if ( version_compare( TB_FRAMEWORK_VERSION, '2.4.0', '<' ) ) {
				$output .= sprintf( '<div class="tweet-icon"><i class="icon-%s"></i></div>', $icon );
			} else {
				$output .= sprintf( '<div class="tweet-icon"><i class="fa fa-%s"></i></div>', $icon );
			}
		}

		$text = apply_filters( 'tweeple_tweet_text', $tweet['text'], $tweet, $feed_options );
		$output .= sprintf( '<div class="tweet-text tweet-content">%s</div>', $text );

		if ( tweeple_show_tweet_meta( $feed_options ) ) {

			$meta = tweeple_get_tweet_meta_fancy( $tweet );

			if ( version_compare( TB_FRAMEWORK_VERSION, '2.2.0', '<' ) ) {
				$output .= sprintf( '<span style="font-size:1rem;">%s</span>', $meta ); // Inline styles, barf. Oh, what I do for you, backwards compat.
			} else {
				$output .= $meta;
			}

		}

		$output .= '</div><!-- .tb-tweet-wrapper (end) -->';

		$count++;
	}

	return $output;
}

/*------------------------------------------------------------*/
/* (2) Helpers
/*------------------------------------------------------------*/

/**
 * Get error for a Twitter feed.
 *
 * @since 0.5.0
 *
 * @param string $feed A Twitter feed
 * @return string Error message for a feed, or null if no error.
 */
function tweeple_error( $feed ) {

	if ( ! empty( $feed['error'] ) ) {
		return $feed['error'];
	}

	return null;
}

/**
 * Get a Twitter feed.
 *
 * @since 0.5.0
 *
 * @param mixed $feed_id An ID of a tweeple_feed post
 * @return array The feed options and Tweets
 */
function tweeple_get_feed( $feed_id ) {
	$tweeple_feed = new Tweeple_Feed( $feed_id );
	return $tweeple_feed->get_feed();
}

/**
 * Get Tweets from a Twitter feed.
 *
 * @since 0.5.0
 *
 * @param array $feeds A single Twitter feed or array of multiple twitter feeds.
 * @return array Tweets to display in chronological order
 */
function tweeple_get_tweets( $feeds ) {

	if ( ! is_array( $feeds ) ) {
		return null;
	}

	// If this is a single Twitter feed
	if ( isset( $feeds['tweets'] ) ) {
		if ( is_array( $feeds['tweets'] ) ) {
			return $feeds['tweets'];
		} else {
			return array();
		}
	}

	// If this is a single Twitter feed, but for
	// some reason, passed in a bigger array
	if ( count( $feeds ) == 1 ) {
		if ( isset( $feeds[0]['tweets'] ) && is_array( $feeds[0]['tweets'] ) ) {
			return $feeds[0]['tweets'];
		} else {
			return array();
		}
	}

	// Merge multiple Twitter feeds
	$tweets = array();
	foreach ( $feeds as $feed ) {
		if ( isset( $feed['tweets'] ) && is_array( $feed['tweets'] ) ) {
			$tweets = array_merge( $tweets, $feed['tweets'] );
		}
	}

	// Re-sort new merged array chronilogically.
	uasort( $tweets, 'tweeple_do_time_compare' );

	return $tweets;

}

/**
 * A callback for uasort() to merge Twitter
 * feeds and arrange chronicalogically.
 *
 * @since 0.5.0
 */
function tweeple_do_time_compare( $item1, $item2 ) {
	$ts1 = strtotime( $item1['time'] );
	$ts2 = strtotime( $item2['time'] );
	return $ts2 - $ts1;
}

/**
 * Display meta for a Tweet.
 *
 * @since 0.5.0
 *
 * @param array $tweet Information for current tweet being displayed
 */
function tweeple_tweet_meta( $tweet ) {
	do_action( 'tweeple_tweet_meta', $tweet );
}

/**
 * Get display meta for a Tweet.
 *
 * @since 0.5.0
 *
 * @param array $tweet Information for current tweet being displayed
 * @return string The meta infor for the Tweet
 */
function tweeple_get_tweet_meta( $tweet ) {
	ob_start();
	do_action( 'tweeple_tweet_meta', $tweet );
	return ob_get_clean();
}

/**
 * Whether to show meta for a Tweet or not.
 *
 * @since 0.5.0
 *
 * @param array $feed A Twitter feed
 */
function tweeple_show_tweet_meta( $feed ) {

	if ( isset( $feed['time'] ) && $feed['time'] == 'yes' ) {
		return true;
	}

	return false;
}