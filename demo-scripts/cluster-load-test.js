// this cluster load test does stress the cluster specified by the environment variable ENDPOINT 
// for 1 minute by sending a request every 0.2 seconds from 3400 concurrently.  

import http from 'k6/http';
import { sleep } from 'k6';

export let options = {
    vus: 3400, // Virtual Users
    duration: '60s', // Test duration
};

export default function () {
    const endpoint = __ENV.ENDPOINT;
    http.get(endpoint);
    sleep(0.2);
}
