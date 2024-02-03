export class Deck {
    _cards: number[];

    static fromArray(cards: number[]): Deck {
        const deck = new Deck();
        deck.setDeck(cards);
        return deck;
    }

    constructor() {
        this._cards = [];
        for (let i = 0; i < 52; i++) {
            this._cards.push(i);
        }
        this.shuffleCards();
    }

    protected setDeck(cards: number[]) {
        this._cards = cards;
    }

    public get cards(): number[] {
        return Array.from(this._cards);
    }

    draw(amt: number): number[] {
        return this._cards.splice(0, amt)
    }

    addToBottom(cards: number[]) {
        this._cards.push(...cards);
    }

    protected shuffleCards() {
        for (let i = this._cards.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [this._cards[i], this._cards[j]] = [this._cards[j], this._cards[i]];
        }
    }

}
