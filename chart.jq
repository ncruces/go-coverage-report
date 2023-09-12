.[0].data.labels=(.[1][0]|map(.*1000)) |
.[0].data.datasets[0].data=.[1][1] |
.[0]