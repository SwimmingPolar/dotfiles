return {
    'rcarriga/nvim-notify',
    keys = {{'<leader-n>', function()
        require('notify').dismiss {
            silent = true,
            pending = true
        }
    end}},
    opts = {
        fps = 60,
        stages = 'slide'
    }
}
