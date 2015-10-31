jsToolBar.prototype.setMoreLink = function(link) {
    this.more_link = link;
};

jsToolBar.prototype.elements.more = {
    type: 'button',
    title: 'More',
    fn: {
        wiki: function() {
            window.open(this.more_link, '', 'resizable=yes, location=no, width=300, height=640, menubar=no, status=no, scrollbars=yes');
        }
    }
};
