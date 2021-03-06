module.exports = ({ env }) => ({
  defaultConnection: 'default',
  connections: {
    default: {
      connector: 'bookshelf',
      settings: {
        client: 'postgres',
        host: env('DATABASE_HOST'),
        port: env.int('DATABASE_PORT'),
        database: env('DATABASE_NAME'),
        username: env('DATABASE_USER'),
        password: env('DATABASE_PASS'),
        ssl: env.bool('DATABASE_SSL', false),
      },
      options: {}
    },
  },
});
