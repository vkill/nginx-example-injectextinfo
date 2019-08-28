function inject_extinfo(s) {
    var req = '';
    s.on('upload', function(data, flags) {
        s.log('data: ' + data)
        s.log('flags: ' + Object.entries(flags))

        var v = s.variables;
        var x = v.var_x;
        req += String.bytesFrom(uint16Array(x.length));
        req += x;
        req += '\r\n';

        s.send(req + data, flags);
        s.off('upload');
    });
}

function uint16Array(n) {
    var str = (Array(4).join('0') + parseInt(n).toString(16)).slice(-4)
    return ['0x' + str[0,0] + str[1,1], '0x' + str[2,2] + str[3,3]]
}
