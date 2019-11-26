db.createUser({
  user: "ticket_system",
  pwd: "ticketpass",
  roles: [
    {
      role: "readWrite",
      db: "ticket_system"
    }
  ]
});
