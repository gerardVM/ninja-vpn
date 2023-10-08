'use strict';

exports.handler = async (event) => {
    const request = event.Records[0].cf.request;

    // Add your custom header to the request
    request.headers['x-origin-verify'] = [{
        key: 'x-origin-verify',
        value: 'valid-token'
    }];

    return request;
};
