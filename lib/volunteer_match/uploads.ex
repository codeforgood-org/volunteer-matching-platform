defmodule VolunteerMatch.Uploads do
  @moduledoc """
  The Uploads context manages file uploads to S3.
  """

  alias ExAws.S3

  @bucket Application.compile_env(:volunteer_match, :s3_bucket, "volunteer-match-uploads")

  @doc """
  Uploads a file to S3 and returns the URL.
  """
  def upload_file(file_binary, filename, content_type) do
    key = generate_key(filename)

    case S3.put_object(@bucket, key, file_binary, content_type: content_type, acl: :public_read)
         |> ExAws.request() do
      {:ok, _} ->
        {:ok, get_url(key)}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Uploads an avatar image.
  """
  def upload_avatar(file_binary, user_id, extension) do
    filename = "avatars/#{user_id}.#{extension}"
    upload_file(file_binary, filename, get_content_type(extension))
  end

  @doc """
  Uploads an NGO logo.
  """
  def upload_logo(file_binary, ngo_id, extension) do
    filename = "logos/#{ngo_id}.#{extension}"
    upload_file(file_binary, filename, get_content_type(extension))
  end

  @doc """
  Uploads an opportunity image.
  """
  def upload_opportunity_image(file_binary, opportunity_id, extension) do
    filename = "opportunities/#{opportunity_id}.#{extension}"
    upload_file(file_binary, filename, get_content_type(extension))
  end

  @doc """
  Uploads a verification document.
  """
  def upload_verification_document(file_binary, ngo_id, document_name) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    filename = "verification/#{ngo_id}/#{timestamp}_#{document_name}"
    upload_file(file_binary, filename, "application/pdf")
  end

  @doc """
  Deletes a file from S3.
  """
  def delete_file(key) do
    S3.delete_object(@bucket, key)
    |> ExAws.request()
  end

  @doc """
  Gets a presigned URL for temporary access.
  """
  def get_presigned_url(key, expires_in \\ 3600) do
    config = ExAws.Config.new(:s3)
    {:ok, url} = S3.presigned_url(config, :get, @bucket, key, expires_in: expires_in)
    url
  end

  defp generate_key(filename) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
    "#{timestamp}_#{random}_#{filename}"
  end

  defp get_url(key) do
    region = Application.get_env(:ex_aws, :region, "us-east-1")
    "https://#{@bucket}.s3.#{region}.amazonaws.com/#{key}"
  end

  defp get_content_type(extension) do
    case extension do
      "jpg" -> "image/jpeg"
      "jpeg" -> "image/jpeg"
      "png" -> "image/png"
      "gif" -> "image/gif"
      "pdf" -> "application/pdf"
      "doc" -> "application/msword"
      "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      _ -> "application/octet-stream"
    end
  end
end
