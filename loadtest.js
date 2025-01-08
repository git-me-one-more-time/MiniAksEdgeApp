import http from 'k6/http';
import { sleep } from 'k6';

export let options = {
    vus: 3000, // Virtual Users
    duration: '80s', // Test duration
};

export default function () {
    http.get('http://miniedgeapp.westeurope.cloudapp.azure.com/');
    sleep(0.1);
}
