class WalletsController < ActionController::API
  def create
    wallet = Wallet.find_or_initialize_by(wallet_params)
    wallet.last_connected_at = Time.current

    if wallet.persisted?
      wallet.save # saving last_connected_at

      return head 200
    end

    if wallet.save
      head 201
    else
      render json: { errors: wallet.errors.full_messages }, status: 422
    end
  end

  def wallet_params
    params.require(:wallet).permit(:stake_address)
  end
end