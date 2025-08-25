const express = require("express");
const supabase = require("./supabaseClient"); 

require("dotenv").config();

const app = express();
const port = 3001;

// New endpoint to test Supabase connection
app.get("/test", async (req, res) => {
  const { data, error } = await supabase.from("test_table").select("*");

  if (error) {
    return res.status(500).json({ error: error.message });
  }

  res.json(data);
});

app.listen(port, () => {
  console.log(`Backend server listening on http://localhost:${port}`);
});
