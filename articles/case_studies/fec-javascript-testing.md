# Testing and refactoring JavaScript with FEC

Until August of this year, the JavaScript for the OpenFEC project had no unit tests. This wasn't because the development team wasn't interested in testing--our backend code was already thoroughly tested. Instead, our JavaScript code just wasn't pleasant to test. Here's an example of the coding style that prevailed not long ago:

```javascript
$(document).ready(function() {
  var $widget = $('#widget');
  $widget.on('click', function() {
    $.getJSON($widget.data('url')).done(function(response) {
      $widget.find('.content').text(response.content);
    }).fail(function(error) {
      alert('It broke!');
    });
  });
});
```

Because this is a toy example, it's not too hard to tell what this code does:
* On document load, bind a click listener to the widget element
* On click, fetch data from the associated URL
* If the request succeeds, show the contents in the widget
* If the request fails, show a warning dialog

But even this simple example is fairly complicated to test. For example, to test that the widget's text is updated on loading data, we would have to stub `$.getJSON` to respond with some known text rather than making a real AJAX request, then trigger the document ready and widget click events. There would be far more code written on test setup and teardown than on the tests themselves, and test-writing would be laborious and error-prone.

Confronted with this situation, the team initially followed in the time-honored tradition of developers working with poorly organized: we didn't write unit tests. We did have a suite of Selenium tests, but they were slow to run and cumbersome to maintain. Finally, we decided to begin refactoring our scripts to make unit tests possible, and then to write them. Here's the toy example from above, but without the pyramid of callbacks:

```javascript
function Widget(selector) {
  this.$element = $(selector);
  this.$element.on('click', this.fetchData.bind(this));
}

Widget.prototype = {
  fetchData: function() {
    var promise = $.getJSON(this.$element.data('url'));
    promise.done(this.renderData.bind(this));
    promise.fail(this.renderError.bind(this));
  },
  renderData: function(response) {
    this.$element.find('.content').text(response.content);
  },
  renderError: function(error) {
    alert('It broke!');
  }
};

$(document).ready(function() {
  var widget = new Widget('#widget');
});
```

This code is a bit more verbose than the first example, but also less indented, and easier to read. More important, it's also easy to test: because each behavior of the `Widget` class is implemented in a separate method, we can test one behavior without the others getting in the way. Now we can test whether text is properly updated without faking an AJAX request:

```javascript
describe('widget', function() {
  beforeEach(function() {
    /* Setup boilerplate */
  });
  
  it('should render text when it receives data', function() {
    this.widget.renderData({content: 'test content'});
    expect(this.widget.find('.content').text()).to.equal('test content');
  });
});
```

These tests are straightforward to read and write. In fact, two members of the FEC team wrote their first JavaScript unit tests after we switched to this style. And unlike the Selenium tests, they run in milliseconds rather than minutes. Now our tests are fast enough to write and to run that we can reasonably expect every patch to come with tests, and we aren't tempted to merge changes while we wait on a slow build.

Throughout the process of refactoring and testing our client-side code, we've learned that writing testable code is just as important as writing unit tests. Developers probably won't take testing seriously when tests are painful to write--and painful testing is likely evidence of code that's overdue for refactoring.
