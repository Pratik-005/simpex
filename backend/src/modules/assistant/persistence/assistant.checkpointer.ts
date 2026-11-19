import { MongoDBSaver } from '@langchain/langgraph-checkpoint-mongodb';
import mongoose from 'mongoose';

class AssistantStateClient {

  private saver: MongoDBSaver | null = null;
  private setupPromise: Promise<MongoDBSaver> | null = null;

  async getSaver(): Promise<MongoDBSaver> {
    if (this.saver) return this.saver;
    if (mongoose.connection.readyState !== 1) {
      throw new Error('MongoDB must be connected before initializing the assistant checkpointer');
    }
    if (!this.setupPromise) {
      this.setupPromise = (async () => {
        const client = mongoose.connection.getClient();
        const saver = new MongoDBSaver({
          client,
          dbName: mongoose.connection.name,
          checkpointCollectionName: 'assistant_checkpoints',
          checkpointWritesCollectionName: 'assistant_checkpoint_writes',
          ttl: 60 * 60 * 24 * 30,
        });
        const errors = await saver.setup();
        if (errors.length) throw new AggregateError(errors, 'Failed to initialize assistant checkpoint indexes');
        this.saver = saver;
        return saver;
      })();
    }
    return this.setupPromise;
  }
}

export const assistantStateClient = new AssistantStateClient();
