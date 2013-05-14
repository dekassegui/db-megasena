window.addEvent(
  'domready',
  function () {
    var myTips = new Tips(
      $$('*[title]').each(
        function (element) {
          var texto = element.get('title').replace(/(?:\d+\.)?\d+/g, '<strong>$&</strong>').split(/\s*::\s*/);
          element.store('tip:title', texto[0]);
          texto[1] && element.store('tip:text', texto[1]);
        }),
      {
        onShow: function (tip, el) {
                  tip.setStyles({
                    visibility: 'hidden',
                       display: 'block'
                  }).fade('in');
                },
        onHide: function (tip, el) {
                  tip.fade('out').get('tween').chain(
                    function () { tip.setStyle('display', 'none') });
                }
      }
    );

    var winScroller = new Fx.Scroll(window);

    $$('h2').each(
      function (element) {
        element
          .set('title', 'clique para alternar a visibilidade do parágrafo')
          .addEvent('click', function (event) {
              event.stop();
              var h2 = this;
              var div = h2.getNext();
              div.getFirst().get('slide').toggle().chain(
                function () { div.getHeight() && winScroller.toElement(h2) });
            })
          .getNext().set('slide', {
                duration: Math.max(element.getNext().getHeight() * 2, 750),
              //transition: Fx.Transitions.Bounce.easeOut,
            }).slide('hide');
      });
  }
)
