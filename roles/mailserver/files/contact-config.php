<?php

return [
    'subject' => [
        'prefix' => '[Contact Form]'
    ],
    'emails' => [
        'to'   => 'contact@{{ server_host_name }}',
        'from' => 'postmaster@{{ server_host_name }}'
    ],
    'messages' => [
        'error'   => 'There was an error sending, please try again later.',
        'success' => 'Your message has been sent successfully.'
    ],
    'fields' => [
        'name'     => 'Name',
        'email'    => 'Email',
        'phone'    => 'Phone',
        'subject'  => 'Subject',
        'message'  => 'Message',
        'btn-send' => 'Send'
    ]
];
