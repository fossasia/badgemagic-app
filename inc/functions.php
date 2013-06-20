<?php
/**
 * Default display for Twitter feed.
 *
 * @since 0.1.0
 */
function tweeple_display_default( $feed ) {
	echo tweeple_get_display_default( $feed );
}

/**
 * Get default display for Twitter feed.
 *
 * @since 0.1.0
 */
function tweeple_get_display_default( $feed ) {

	$output = '';

	// Check for tweets
	if( ! $feed['tweets'] )
		return __('No tweets to display.', 'tweeple');

	$output .= '<ul class="tweets">';

	// Loop through tweets
	foreach( $feed['tweets'] as $tweet ) {

		$output .= '<li class="tweet">';
		$output .= '<div class="tweet-wrap">';

		$text = apply_filters( 'tweeple_tweet_text', $tweet['text'], $tweet, $feed );
		$output .= sprintf( '<div class="tweet-text">%s</div>', $text );

		if( $feed['time'] == 'yes' ) {
			$output .= '<div class="tweet-time">';
			ob_start();
			do_action( 'tweeple_tweet_timestamp', $tweet );
			$output .= ob_get_clean();
			$output .= '</div>';
		}

		$output .= '</div><!-- .tweet-wrap (end) -->';
		$output .= '</li>';
	}

	$output .= '</ul>';

	return $output;

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
	$text = preg_replace("/#(\w+)/", "<a class=\"twitter-link\" href=\"http://search.twitter.com/search?q=\\1\" target=\"_blank\">#\\1</a>", $text);

	// Format @username as links
	$text = preg_replace("/@(\w+)/", "<a class=\"twitter-link\" href=\"http://twitter.com/\\1\" target=\"_blank\">@\\1</a>", $text);

    return $text;
}

/**
 * Default timestamp for tweets.
 *
 * @since 0.1.0
 */
function tweeple_tweet_timestamp_default( $tweet ) {
	$status_url = sprintf( 'https://twitter.com/%s/status/%s', $tweet['author'], $tweet['id_str'] );
	$time = date_i18n( get_option('date_format'), strtotime( $tweet['time'] ) );
	printf( '<a href="%s" title="%s" target="_blank">%s</a>', $status_url, $time, $time );
}

/**
 * A fancier timestamp that could be used for tweets. Currently not hooked to anything.
 *
 * @since 0.1.0
 */
function tweeple_tweet_timestamp_fancy( $tweet ) {

	// Status link
	$status_url = sprintf( 'https://twitter.com/%s/status/%s', $tweet['author'], $tweet['id_str'] );
	$time = date_i18n( get_option('date_format'), strtotime( $tweet['time'] ) );
	$time_link = sprintf( '<a href="%s" title="%s" target="_blank">%s</a>', $status_url, $time, $time );

	// Author link
	$author_url = sprintf( 'https://twitter.com/%s', $tweet['author'] );
	$author_link = sprintf( '<a href="%s" title="%s" target="_blank">%s</a>', $author_url, $tweet['author'], $tweet['author'] );

	// Final time stamp
	$timestamp = sprintf( '<span class="tweet-stamp">%s</span> <span class="tweet-author">%s %s</span>', $time_link, __( 'via', 'tweeple' ), $author_link );

	echo '<div class="tweet-time tweet-meta">'.$timestamp.'</div>';

}

/**
 * Default display for "Tweet" element for Theme
 * Blvd Layout Builder.
 *
 * @since 0.4.0
 */
function tweeple_tweet_element_default( $feed, $options ) {
	echo tweeple_get_tweet_element_default( $feed, $options );
}

/**
 * Get default display for "Tweet" element for Theme
 * Blvd Layout Builder.
 *
 * @since 0.4.0
 */
function tweeple_get_tweet_element_default( $feed, $options ) {

	if( ! defined( 'TB_FRAMEWORK_VERSION' ) || ! defined( 'TB_BUILDER_PLUGIN_VERSION' ) )
		return;

	if( ! $feed['tweets'] )
		return __('No tweets to display.', 'tweeple');

	$icon = $options['icon'];

	// Convert older icon option for those updating.
	if( version_compare( TB_FRAMEWORK_VERSION, '2.2.0', '>=' ) ) {
		switch( $icon ) {
			case 'message' :
				$icon = 'comment';
				break;
			case 'alert' :
				$icon = 'warning';
				break;
		}
	}

	$wrap_class = 'tb-tweet-wrapper';
	if( $icon )
		$wrap_class .= ' has-icon';

	$output = '';
	$count = 1;
	$max = apply_filters( 'tweeple_tweet_element_max_count', 1 ); // @todo Possibly make option later

	foreach( $feed['tweets'] as $tweet ) {

		if( $count > $max )
			break;

		$output .= sprintf( '<div class="%s">', $wrap_class );

		if( $icon )
			$output .= sprintf( '<div class="tweet-icon"><i class="icon-%s"></i></div>', $icon );

		$text = apply_filters( 'tweeple_tweet_text', $tweet['text'], $tweet, $feed );
		$output .= sprintf( '<div class="tweet-text tweet-content">%s</div>', $text );

		if( $feed['time'] == 'yes' ) {

			ob_start();
			tweeple_tweet_timestamp_fancy( $tweet );
			$timestamp = ob_get_clean();

			if( version_compare( TB_FRAMEWORK_VERSION, '2.2.0', '<' ) )
				$output .= sprintf( '<span style="font-size:1rem;">%s</span>', $timestamp ); // Inline styles, barf. Oh, what I do for you, backwards compat.
			else
				$output .= $timestamp;

		}

		$output .= '</div><!-- .tb-tweet-wrapper (end) -->';

		$count++;
	}

	return $output;
}