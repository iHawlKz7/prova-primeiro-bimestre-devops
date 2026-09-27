const express = require("express");
const { Pool } = require("pg");

const app = express();

app.use(express.json());

const PORT = process.env.PORT || 3000;

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT || 5432),
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
  database: process.env.DB_NAME || "reservas",
});

async function inicializarBanco() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS reservas (
      id SERIAL PRIMARY KEY,
      cliente VARCHAR(255) NOT NULL,
      data DATE NOT NULL,
      status VARCHAR(50) NOT NULL
    );
  `);

  console.log("Tabela reservas pronta.");
}

app.get("/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");

    res.status(200).json({
      status: "ok",
      database: "connected",
    });
  } catch (error) {
    res.status(503).json({
      status: "error",
      database: "disconnected",
    });
  }
});

app.post("/reservas", async (req, res) => {
  const { cliente, data, status } = req.body;

  if (!cliente || !data || !status) {
    return res.status(400).json({
      erro: "cliente, data e status são obrigatórios",
    });
  }

  try {
    const result = await pool.query(
      `
        INSERT INTO reservas (cliente, data, status)
        VALUES ($1, $2, $3)
        RETURNING *
      `,
      [cliente, data, status]
    );

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      erro: "Erro ao criar reserva",
    });
  }
});

app.get("/reservas", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM reservas ORDER BY id"
    );

    return res.json(result.rows);
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      erro: "Erro ao listar reservas",
    });
  }
});

app.get("/reservas/:id", async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      "SELECT * FROM reservas WHERE id = $1",
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        erro: "Reserva não encontrada",
      });
    }

    return res.json(result.rows[0]);
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      erro: "Erro ao buscar reserva",
    });
  }
});

app.put("/reservas/:id", async (req, res) => {
  const { id } = req.params;
  const { cliente, data, status } = req.body;

  if (!cliente || !data || !status) {
    return res.status(400).json({
      erro: "cliente, data e status são obrigatórios",
    });
  }

  try {
    const result = await pool.query(
      `
        UPDATE reservas
        SET cliente = $1,
            data = $2,
            status = $3
        WHERE id = $4
        RETURNING *
      `,
      [cliente, data, status, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        erro: "Reserva não encontrada",
      });
    }

    return res.json(result.rows[0]);
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      erro: "Erro ao atualizar reserva",
    });
  }
});

app.delete("/reservas/:id", async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `
        DELETE FROM reservas
        WHERE id = $1
        RETURNING *
      `,
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        erro: "Reserva não encontrada",
      });
    }

    return res.status(204).send();
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      erro: "Erro ao excluir reserva",
    });
  }
});

async function iniciarServidor() {
  try {
    await inicializarBanco();

    app.listen(PORT, "0.0.0.0", () => {
      console.log(`API de Reservas executando na porta ${PORT}`);
    });
  } catch (error) {
    console.error("Erro ao inicializar aplicação:", error);
    process.exit(1);
  }
}

iniciarServidor();