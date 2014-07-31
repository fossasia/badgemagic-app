<?php
/**
 * Retrieve and parse a Twitter feed.
 *
 * @since 0.1.0
 */
class Tweeple_Feed {

    private $feed_id = 0;
    private $feed_type = '';
    private $do_cache = true;
    private $do_entities = false;
    private $access = array();
    private $feed_post = null;
    private $feed = null;
    private $raw_feed = null;
    private $error = '';

	/**
     * Constructor
     *
     * @since 0.1.0
     */
    public function __construct( $feed_id = 0 ) {

        $this->feed_id = intval( $feed_id );
        $this->do_cache = apply_filters( 'tweeple_do_cache', true );
        $this->do_entities = apply_filters( 'tweeple_do_entities', false );

    	// First check for cache.
    	if ( $this->do_cache ) {

            $cache = get_transient( 'tweeple_'.$feed_id );

        	if ( $cache ) {
                $this->feed = $cache;
        		return;
        	}
        }

        // Setup access credentials to Twitter
        $this->set_access();

        // Set feed post object
        if ( ! $this->error  ) {
            $this->set_feed_post();
        }

        // Set type of Twitter feed
        if ( ! $this->error  ) {
            $this->set_feed_type();
        }

        // Setup new Twitter feed
        $this->set_feed();

    }

    /**
     * Get feed ID.
     *
     * @since 0.1.0
     */
    public function get_feed_id() {
    	return $this->feed_id;
    }

    /**
     * Get the raw, decoded feed from Twitter.
     * This only available when the cache isn't set.
     *
     * @since 0.1.0
     */
    public function get_raw_feed() {

        if ( ! $this->raw_feed ) {
            return array( 'error' => sprintf(__('Raw feed not available. Clear the cache transient "%s" in order to access raw feed.'), 'tweeple_'.$this->feed_id ) );
        }

        return $this->raw_feed;
    }

    /**
     * Get parsed feed.
     *
     * @since 0.1.0
     */
    public function get_feed() {

        // If tweets were UTF8-encoded when stored, we need to decode
        if ( ! empty( $this->feed['tweets'] ) && is_array( $this->feed['tweets'] ) ) {
            if ( ! empty( $this->feed['options']['encode'] ) && $this->feed['options']['encode'] == 'yes' ) {

                $tweets = array();

                foreach ( $this->feed['tweets'] as $key => $value ) {
                    if ( ! empty( $value['text'] ) ) {
                        $value['text'] = utf8_decode($value['text']);
                    }
                    $tweets[$key] = $value;
                }

                $this->feed['tweets'] = $tweets;
            }
        }

        return $this->feed;
    }

    /**
     * Setup developer application access credentials.
     *
     * @since 0.1.0
     */
    function set_access() {

        // Get "Authorization" options from DB
        $access = get_option( 'tweeple_access' );

        if ( ! $access ) {
            $this->error = __('No developer access for Twitter given.', 'tweeple');
            return;
        }

        $consumer_key = isset( $access['consumer_key'] ) ? $access['consumer_key'] : '';
        $consumer_secret = isset( $access['consumer_secret'] ) ? $access['consumer_secret'] : '';
        $user_token = isset( $access['user_token'] ) ? $access['user_token'] : '';
        $user_secret = isset( $access['user_secret'] ) ? $access['user_secret'] : '';

        // Check for any missing info
        $missing = array();

        if ( ! $consumer_key ) {
            $missing[] = 'consumer_key';
        }

        if ( ! $consumer_secret ) {
            $missing[] = 'consumer_secret';
        }

        if ( ! $user_token ) {
            $missing[] = 'user_token';
        }

        if ( ! $user_secret ) {
            $missing[] = 'user_secret';
        }

        if ( count( $missing ) > 0 ) {
            $this->error = sprintf( __('Missing authorization options: %s', 'tweeple'), implode(', ', $missing ) );
            return;
        }

        // Set object's dev access to Twitter
        $this->access = array(
            'consumer_key'      => $consumer_key,
            'consumer_secret'   => $consumer_secret,
            'user_token'        => $user_token,
            'user_secret'       => $user_secret
        );
    }

    /**
     * Verify that the feed_id belongs to an actual
     * post that exists in the DB and store the post
     * object.
     *
     * @since 0.1.0
     */
    public function set_feed_post() {

        $this->feed_post = get_post( $this->feed_id );

        if ( ! $this->feed_post ) {
            $this->error = __( 'Invalid feed ID given; Twitter feed does not exist.', 'tweeple' );
        }

    }

    /**
     * Set the type of feed.
     *
     * @since 0.1.0
     */
    public function set_feed_type() {

        $this->feed_type = get_post_meta( $this->feed_id, 'feed_type', true );

        $types = apply_filters( 'tweeple_feed_types', array( 'user_timeline', 'search', 'list', 'favorites' ) );

        if ( ! in_array( $this->feed_type, $types ) ) {
            $this->feed_type = $types[0];
        }

    }

    /**
     * Set the feed array. This is the big kahuna.
     *
     * When interacting with our class to display a
     * Twitter feed, the main thing being retrieved
     * is the $feed property, which this sets up.
     *
     * @since 0.1.0
     */
    public function set_feed() {

        $tweets = array();

        // Get tweets from Twitter. This could result in
        // errors, so we're doing it above our error checking.
        if ( ! $this->error ) {
            $tweets = $this->get_tweets();
        }

        // Check for error
        if ( $this->error ) {
            $this->feed = array( 'error' => $this->error );
        }

        // If there was no error, setup feed.
        if ( ! $this->feed ) {

            // Setup feed array
            $this->feed = array(
                'info' => array(
                    'id'                => $this->feed_id,
                    'type'              => $this->feed_type,
                    'name'              => $this->feed_post->post_title,
                ),
                'options' => array(
                    'screen_name'       => get_post_meta( $this->feed_id, 'screen_name', true ),
                    'slug'              => get_post_meta( $this->feed_id, 'slug', true ),
                    'owner_screen_name' => get_post_meta( $this->feed_id, 'owner_screen_name', true ),
                    'search'            => get_post_meta( $this->feed_id, 'search', true ),
                    'result_type'       => get_post_meta( $this->feed_id, 'result_type', true ),
                    'exclude_retweets'  => get_post_meta( $this->feed_id, 'exclude_retweets', true ),
                    'exclude_replies'   => get_post_meta( $this->feed_id, 'exclude_replies', true ),
                    'time'              => get_post_meta( $this->feed_id, 'time', true ),
                    'count'             => get_post_meta( $this->feed_id, 'count', true ), // Display count, NOT raw count.
                    'encode'            => get_post_meta( $this->feed_id, 'encode', true )
                ),
                'tweets'                => null
            );

            // Get response from Twitter
            if ( count( $tweets ) > 0 ) {
                $this->feed['tweets'] = $tweets;
            }

        }

        // Caching
        if ( $this->do_cache ) {

            // Setup the time the feed will be cached.
            $cache_time = intval( esc_attr( get_post_meta( $this->feed_id, 'cache', true ) ) );
            if ( ! $cache_time ) {
                $cache_time = 7200; // 2 hours
            }

            // Cache it.
            set_transient( 'tweeple_'.$this->feed_id, $this->feed, $cache_time );

        }

    }

    /**
     * Setup the request for Twitter and retrieve
     * the tweets.
     *
     * @since 0.1.0
     */
    public function get_tweets() {

        // Establish tmhOAuth wrap with access credientials
        $twitter = new tmhOAuth( $this->access );

        // Start request params
        $params = array();
        $resource = '';

        switch ( $this->feed_type ) {

            // User timeline
            case 'user_timeline' :

                $screen_name = get_post_meta( $this->feed_id, 'screen_name', true );

                if ( ! $screen_name ) {
                    $this->error = __('No Twitter username given.', 'tweeple');
                    return;
                }

                $params['include_rts'] = true;
                $params['exclude_replies'] = false;
                $params['screen_name'] = $screen_name;
                $resource = 'statuses/user_timeline';

                break;

            // Search results
            case 'search' :

                $search = get_post_meta( $this->feed_id, 'search', true );
                $result_types = apply_filters( 'tweeple_result_types', array( 'mixed', 'popular', 'recent' ) );
                $result_type = get_post_meta( $this->feed_id, 'result_type', true );

                if ( ! in_array( $result_type, $result_types ) ) {
                    $result_type = 'mixed';
                }

                if ( ! $search ) {
                    $this->error = __('No search term given.', 'tweeple');
                    return;
                }

                $params['q'] = urlencode( $search );
                $params['result_type'] = $result_type;
                $resource = 'search/tweets';

                break;

            case 'list' :

                $slug = get_post_meta( $this->feed_id, 'slug', true );
                $screen_name = get_post_meta( $this->feed_id, 'owner_screen_name', true );

                if ( ! $slug || ! $screen_name ) {
                    $this->error = __('No list slug and/or owner username given.', 'tweeple');
                    return;
                }

                $params['include_rts'] = true;
                $params['slug'] = $slug;
                $params['owner_screen_name'] = $screen_name;
                $resource = 'lists/statuses';

                break;

            case 'favorites' :

                $screen_name = get_post_meta( $this->feed_id, 'screen_name', true );

                if ( ! $screen_name ) {
                    $this->error = __('No Twitter username given.', 'tweeple');
                    return;
                }

                $params['screen_name'] = $screen_name;
                $resource = 'favorites/list';

                break;
        }

        // Entities
        if ( $this->do_entities ) {
            $params['include_entities'] = true;
        }

        // Set number of tweets to pull before any of Tweeple's
        // parsing, like excluding @replies and retweets.
        $count = intval( get_post_meta( $this->feed_id, 'raw_count', true ) );
        $raw_limit = apply_filters( 'tweeple_raw_count_limit', 30 );

        if ( $count < 1 || $count > $raw_limit ) {
            $count = 10; // Default fallback raw count
        }

        $params['count'] = $count;

        // Extend
        $params = apply_filters( 'tweeple_request_params', $params, $this->feed_type );
        $resource = apply_filters( 'tweeple_request_resource', $resource, $this->feed_type );

        // Fetch from Twitter
        $code = $twitter->request( 'GET', $twitter->url(sprintf('1.1/%s', $resource)), $params );

        // If code was not 200, it means we'll have some sort of error.
        if ( $code != 200 ) {

            $link = sprintf( '<a href="https://dev.twitter.com/docs/error-codes-responses" target="_blank">%s</a>', $code );

            if ( $code == 0 ) {
                $this->error = sprintf( __( 'Security Error from tmhOAuth.', 'tweeple' ), $link );
            } else if ( $code == 401 ) {
                $this->error = sprintf( __( '%s Unauthorized: Authentication credentials were missing or incorrect.', 'tweeple' ), $link );
            } else if ( $code == 404 ) {
                $this->error = sprintf( __( '%s Not Found: The URI requested is invalid or the resource requested, such as a user, does not exists.', 'tweeple' ), $link );
            } else if ( $code == 429 ) {
                $this->error = sprintf( __( '%s Too Many Requests: Your application\'s rate limit has been exhausted for the resource.', 'tweeple' ), $link );
            } else {
                $this->error = sprintf( __( 'Twitter sent back an error. Error code: %s', 'tweeple'), $link );
            }

            return null;
        }

        // We've got the green light; so parse and send back tweets.
        return $this->parse_tweets( $twitter->response['response'] );

    }

    /**
     * Parse response of tweets from Twitter. This happens
     * before we cache it.
     *
     * @since 0.1.0
     */
    public function parse_tweets( $tweets ) {

    	$counter = 1;
    	$tweets = json_decode( $tweets, true );
        $this->raw_feed = $tweets; // Store raw feed

        $limit = get_post_meta( $this->feed_id, 'count', true );

        if ( ! $limit ) {
            $limit = 3;
        }

        $exclude_retweets = get_post_meta( $this->feed_id, 'exclude_retweets', true );
        $exclude_replies = get_post_meta( $this->feed_id, 'exclude_replies', true );

        if ( $this->feed_type == 'search' ) {
            $tweets = $tweets['statuses'];
        }

        // Start new feed
        $new_tweets = array();

        // Run through raw tweets
    	foreach ( $tweets as $tweet ) {

            // Check for display limit
            if ( $counter > $limit ) {
                break;
            }

            // Retweet (user timeline and lists)
            if ( ( $this->feed_type == 'user_timeline' || $this->feed_type == 'list' ) && isset( $tweet['retweeted_status'] ) ) {
                if ( $exclude_retweets == 'yes' ) {
                    continue; // Skip onto the next tweet
                } else {
                    $tweet = $tweet['retweeted_status'];
                }
            }

            // @Replies (user timeline)
            if ( $this->feed_type == 'user_timeline' && $exclude_replies == 'yes' ) {
                if ( substr( $tweet['text'], 0, 1 ) == '@' ) {
                    continue; // Skip onto the next tweet
                }
            }

            // Build new Tweet
            $new_tweet = array(
                'id_str'                    => $tweet['id_str'],
                'text'                      => $tweet['text'],
                'time'                      => $tweet['created_at'],
                'author'                    => $tweet['user']['screen_name'],
                'profile_image_url'         => $tweet['user']['profile_image_url'],
                'profile_image_url_https'   => $tweet['user']['profile_image_url_https'],
                'retweet_count'             => $tweet['retweet_count'],
                'favorite_count'            => $tweet['favorite_count'],
                'source'                    => $tweet['source'],
                'lang'                      => $tweet['lang']
            );

            // UTF-8 encoding
            $encode = get_post_meta( $this->feed_id, 'encode', true );

            if ( $encode != 'no' ) {
                $new_tweet['text'] = utf8_encode( $new_tweet['text'] );
            }

            if ( $this->do_entities && isset( $tweet['entities'] ) ) {
                $new_tweet['entities'] = $tweet['entities'];
            }

            $new_tweets[] = $new_tweet;

    		$counter++;
    	}

    	return apply_filters( 'tweeple_parse_tweets', $new_tweets, $tweets );
    }
}
