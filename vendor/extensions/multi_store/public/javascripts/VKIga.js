/**
 * @fileoverview This file is to be used for implementing Google Analytics on a website.
 * It is a wrapper class around the GA tracker class and allows you to add custom functionality
 * to GA tracking.
 *
 * @author Andre Wei andrewei@vkistudios.com
 */

 /* Function List
  * Privileged Function list
  * addListener
  * getBaseDomain
  * tagCrossDomainLinks
  */

var GACrossDomainsList = ""; // comma-separated list of base domains to treat as cross-domain.
var numBaseDomainParts = 2; // number of parts in the base domain.  ie www.example.com = 2, www.example.co.uk = 3

/* BEGIN: VKIGA Class */

/**
 * Construct a new VKIGA object.
 * @class This is the GA wrapper class
 * @constructor
 * @param {string} crossDomainsList Comma-separated list of base domains to treat as cross-domain
 * @param {int} numDomainParts Number of parts in the base domain
 * @returns A new VKI tracker
 */

function VKIGA (crossDomainsList, numDomainParts) {

  var _baseDomain = "";
  var _numBaseDomainParts = numDomainParts;

  // set the base domain

  var _splitHost = location.hostname.split('.');

  for (var i = 1; i <= _numBaseDomainParts; i++) {

    _baseDomain = '.' + _splitHost[_splitHost.length - i] + _baseDomain;
  }

  _baseDomain = _baseDomain.substr(1);

  /**
   * Comma-separated list of base domains to treat as cross-domain
   * @private
   * @type string
   */
  var _crossDomains = "";

  if (crossDomainsList != null && typeof(crossDomainsList) == "string")
    _crossDomains = crossDomainsList;

  /* BEGIN: Privileged Functions */

  /**
   * Returns the base domain of the website
   *
   * @privileged
   */
  this.getBaseDomain = function() {
    return _baseDomain;
  }

  /**
   *  Adds event handler for specified event to an element
   *
   * @privileged
   * @param {object} element Element to add event listener to
   * @param {string} type Event to listen for.  Do not prepend event with 'on', as the functions automatically prepends it
   * @param {object} expression Javascript function to execute on event.  Can be either a function name or anonymous function
   * @param {boolean} bubbling Sets whether to register the event on bubbling phase (true) or capturing phase (false).  Only applies to W3C compliant browsers.
   * @returns  True on success, false on failure
   * @type boolean
   */
  this.addListener = function (element, type, expression, bubbling) {
    bubbling = bubbling || false;

    if (window.addEventListener) { // Standard
      element.addEventListener(type, expression, bubbling);
      return true;
    } else if(window.attachEvent) { // IE
      element.attachEvent('on' + type, expression);
      return true;
    } else
      return false;
  }

  /* END: Priviledged Functions */

  /* BEGIN: Optional Functionality */

  /**
   * Appends GA cookie information to all anchor tags that are cross-domain links
   *
   * @privileged
   */
  this.tagCrossDomainLinks = function() {

    if (typeof(VKIPageTracker) == "object") {
      // check if getElementsByTagName function exists and we are doing cross-domain tracking
      if ((typeof(document.getElementsByTagName) == "function" || typeof(document.getElementsByTagName) == "object") && _crossDomains != "") {
        anchors = document.getElementsByTagName("a");
        domainsList = _crossDomains.split(",");

        // loop through all anchor tags
        for (i = 0; i < anchors.length; i++) {
          anchor = anchors[i];

          // loop through all our list of cross-domains
          for (j = 0; j < domainsList.length; j++) {
            // don't tag links to this base domain

            if (_baseDomain != domainsList[j]) {
              regexp = new RegExp("^http://.*" + domainsList[j] + "(/?.*)?");

              // if the link matches, append cookie information to link
              if (regexp.test(anchor.href)) {
                anchor.href = VKIPageTracker._getLinkerUrl(anchor.href, true);
              }
            }
          }
        }
      }
    }
  }

  /* END: Optional Functionality */
}

_vkiga = new VKIGA(GACrossDomainsList, numBaseDomainParts);

/* BEGIN: initialize page tracking object */

try {

  var GAWebPropID = ""; // GA account to track data to

  if (_vkiga.getBaseDomain() == 'petwellbeing.com') {
    GAWebPropID = "UA-981819-2";
  }
  else {
    GAWebPropID = "UA-981819-1";
  }

  VKIPageTracker = _gat._getTracker(GAWebPropID);
  VKIPageTracker._setDomainName("." + _vkiga.getBaseDomain());
  VKIPageTracker._setAllowHash(false);
  VKIPageTracker._setAllowAnchor(true);
  VKIPageTracker._setAllowLinker(true);
  VKIPageTracker._setLocalRemoteServerMode();

  /* OPTIONAL */
  // if cross-domain is enabled, tag all links
  if (GACrossDomainsList != "") {
    _vkiga.addListener(window,"load",_vkiga.tagCrossDomainLinks);
  }
  /* OPTIONAL */

  if (document.strTrackPageView)
    VKIPageTracker._trackPageview(document.strTrackPageView);
  else
    VKIPageTracker._trackPageview();
} catch(e) {}

/* END: initialize page tracking object */