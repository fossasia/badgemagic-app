<?php
/**
 * Add any extra functionality for Theme Blvd
 * themes and plugins.
 *
 * @since 0.4.0
 */
class Tweeple_Theme_Blvd {

	/**
     * Only instance of object.
     * @var Tweeple_Theme_Blvd
     */
    private static $instance = null;

    /**
     * Creates or returns an instance of this class.
     *
     * @return Tweeple_Theme_Blvd A single instance of this class.
     *
     * @since 0.4.0
     */
    public static function get_instance() {
        if ( self::$instance == null ) {
            self::$instance = new self;
        }
        return self::$instance;
    }

	/**
     * Run Theme Blvd integration.
     *
     * @since 0.4.0
     */
    private function __construct() {

    	// Add Tweet element to Layout Builder
    	add_filter( 'themeblvd_registered_elements', array( $this, 'registered_elements' ) );
    	add_filter( 'themeblvd_core_elements', array( $this, 'core_elements' ) );
    	add_action( 'themeblvd_tweeple_tweet', array( $this, 'tweet_element' ), 10, 2 );

    }

    /**
     * Register the new Tweet element and de-register
     * the old Tweet element, if it exists.
     *
     * @since 0.4.0
     */
    public function registered_elements( $elements ) {

    	if ( version_compare( TB_FRAMEWORK_VERSION, '2.2.0', '>=' ) ) {
    		unset( $elements['tweet'] );
    		$elements[] = 'tweeple_tweet';
    	}

    	return $elements;
    }

    /**
     * Setup the Tweet elements options for the Builder.
     *
     * @since 0.4.0
     */
    public function core_elements( $elements ) {

    	$tweeple = Tweeple::get_instance();

    	// Before TB framework version 2.2, we're overriding the "Tweet"
    	// element, but after that, we're creating a new element.
    	$id = 'tweet';
    	if ( version_compare( TB_FRAMEWORK_VERSION, '2.2.0', '>=' ) ){
    		$id = 'tweeple_tweet';
    		unset( $elements['tweet'] );
    	}

    	// Start new "Tweet" element.
    	$elements[$id] = array();

		// Information
		$elements[$id]['info'] = array(
			'name' 		=> __( 'Tweet', 'tweeple' ),
			'id'		=> $id,
			'query'		=> 'none',
			'hook'		=> null,
			'shortcode'	=> null,
			'desc' 		=> __( 'Shows the most recent tweet from a Tweeple Twitter feed.', 'tweeple' )
		);

		// Options
		$elements[$id]['options'] = array();

		if ( version_compare( TB_FRAMEWORK_VERSION, '2.2.0', '>=' ) ) {

			// Info type option not styled in builder prior to framework v2.2
			$elements[$id]['options']['slider_desc'] = array(
				'id' 		=> 'slider_desc',
				'desc' 		=> sprintf( __( 'The "Tweet" element works with the %s plugin you\'ve installed. Use it for a large display of the most recent tweet from one of your Twitter feeds setup at Tools > Tweeple.', 'tweeple' ), '<a href="http://wordpress.org/extend/plugins/tweeple" target="_blank">Tweeple</a>' ),
				'type' 		=> 'info'
			);

		}

		$elements[$id]['options']['feed_id'] = array(
			'id' 		=> 'feed_id',
			'name'		=> __( 'Twitter Feed', 'tweeple' ),
			'desc'		=> __( 'Select from the Twitter Feeds you\'ve created at <em>Tools > Tweeple</em>.', 'tweeple' ),
			'type'		=> 'select',
			'std'		=> '',
			'options'	=> $tweeple->get_feeds()
		);

		if ( version_compare( TB_FRAMEWORK_VERSION, '2.2.0', '>=' ) ) {

			$elements[$id]['options']['icon'] = array(
		    	'id' 		=> 'icon',
				'name'		=> __( 'Icon', 'tweeple' ),
				'desc'		=> __( 'Enter any Font Awesome icon ID; this icon will then display next to the Tweet. Set this option blank to not use any icon. Examples: twitter, pencil, warning-sign, etc.', 'tweeple' ),
				'type'		=> 'text',
				'std'		=> 'twitter'
			);

		} else {

			// Before framework v2.2, there was no FontAwesome.
			$elements[$id]['options']['icon'] = array(
		    	'id' 		=> 'icon',
				'name'		=> __( 'Icon', 'tweeple' ),
				'desc'		=> __( 'Select the icon you\'d like shown before the Tweet.', 'tweeple' ),
				'type'		=> 'select',
				'std'		=> 'twitter',
				'options'	=> array(
			        'twitter' 	=> __( 'Twitter Icon', 'tweeple' ),
			        'message' 	=> __( 'Generic Message Bubble', 'tweeple' ),
			        'alert' 	=> __( 'Alert Symbol', 'tweeple' )
				)
			);

		}

	    $elements[$id]['options']['visibility'] = array(
	    	'id' 		=> 'visibility',
			'name'		=> __( 'Responsive Visibility ', 'tweeple' ),
			'desc'		=> __( 'Select any resolutions you\'d like to <em>hide</em> this element on. This is optional, but can be utilized to deliver different content to different devices.<br><br><em>Example: Hide an element on tablets and mobile devices & then create a second element that\'s hidden only on standard screen resolutions to take its place.</em>', 'tweeple' ),
			'type'		=> 'multicheck',
			'options'	=> array(
				'hide_on_standard' 	=> __( 'Hide on Standard Resolutions', 'tweeple' ),
				'hide_on_tablet' 	=> __( 'Hide on Tablets', 'tweeple' ),
				'hide_on_mobile' 	=> __( 'Hide on Mobile Devices', 'tweeple' )
			)
		);

    	return $elements;
    }

    /**
     * Display Tweet element of the Layout Builder.
     *
     * @since 0.4.0
     */
    public function tweet_element( $id, $options ) {

    	// Get Twitter Feed
		$feed = tweeple_get_feed( $options['feed_id'] );
        $tweets = tweeple_get_tweets( $feed );

        if ( ! tweeple_error( $feed )  ) {
            do_action( 'tweeple_display_tweet_element', $tweets, $feed['options'], $options, $id );
        } else {
            printf( '<p>%s</p>', tweeple_error( $feed ) );
        }

    }
}

/**
 * Add backwards compat to any version of Builder
 * or framework using the themeblvd_tweet function.
 *
 * @since 0.4.0
 */
function themeblvd_tweet( $id, $options ) {
    $tweeple = Tweeple_Theme_Blvd::get_instance();
    ob_start();
    $tweeple->tweet_element( $id, $options );
    return ob_get_clean();
}